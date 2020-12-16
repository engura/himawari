# frozen-string-literal: true

require 'httparty'
require 'fileutils'
require 'pathname'
require 'optparse'
# require 'pry'

module Himawari
  MONITOR_ASPECT = 16.0 / 9
  UPDATE_RATE = 2 # int; update the pic once every `UPDATE_RATE` minutes
  HIMAWARI_URL = 'https://himawari8-dl.nict.go.jp/himawari8/img/D531106'

  # Local (JST) midnight happens @14:10 UTC, so we have to use pics in interval of [2.days.ago@14:40 .. 1.day.ago@14:40]
  LOCAL_MIDNIGHT = '1410'

  # sets up the methods for Himawari that do not have to do with accessing the internet. ie:
  #   - it sets up all the default and customized params, builds awareness of the locally stored pics
  #   - implements "setting" the background (copies a downloaded image into a different folder)
  class Base
    attr_reader :now, :app_root, :work_path, :data_path, :destination_path, :focus, :mode, :resolution,
                :latest_local, :latest_remote, :verbose, :by_schedule, :blacklist_wifi, :cron_action

    # relative to the location of the script: Pathname.new(File.expand_path('../', __FILE__))
    # relative to the current working dir:    Dir.pwd
    def initialize(params = {})
      init_paths(params[:workdir])
      @destination_path = params[:destination]

      @now = Time.now.utc
      @focus = params[:focus] || :top
      @mode = params[:mode] || :day
      @resolution = params[:resolution] || 2
      @latest_local = find_latest_local
      @latest_remote = nil
      @verbose = params[:verbose]
      @by_schedule = params[:by_schedule]
      @blacklist_wifi = params[:blacklist] || []
      @cron_action = params[:cron]
    end

    def up_to_date?
      puts "Latest local:    #{latest_local[:timestamp]}" if verbose
      if now - latest_local[:timestamp] < 10 * 60
        puts 'Local pic is up to date; no need to go online.' if verbose
        return true
      end
      false
    end

    def background(img)
      return false unless img && params_valid?

      cmd = "sleep 5 ; rm -f #{destination_path}/*.png ; cp #{img} #{destination_path}"
      # "osascript -e 'tell application \"System Events\" to tell DESKTOP to set picture to \"#{img}\"'"
      puts cmd if verbose
      system(cmd)
    end

    def update_backgrnd
      return false unless mode == :day && params_valid?

      # only rotate the background if we have one complete rotation of the globe saved
      sexy_pics = full_24hrs_available
      # puts sexy_pics
      return false unless sexy_pics

      i = (now.hour * 60 + now.min) / UPDATE_RATE % sexy_pics.count
      puts "#{i} :: #{now.hour * 60 + now.min} % #{sexy_pics.count} switching to #{sexy_pics[i]}" if verbose
      background(sexy_pics[i])
    end

    def crontab(action = nil)
      @cron_action = action if action
      return false unless cron_action && params_valid?

      cmd = '* * * * * PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin himawari ' \
            "-s -m #{mode} -f #{focus} -r #{resolution} -d '#{destination_path}' -w '#{work_path}' -b #{blacklist_wifi.join(',')}"
      OsUtils.crontab(cmd, cron_action)
      cmd
    end

    def params_valid?
      unless %i[full top mid low].include?(focus) && %i[live day].include?(mode) &&
             [2, 4, 8, 16, 20].include?(resolution) && blacklist_wifi.is_a?(Array) &&
             (!destination_path || (destination_path && File.directory?(destination_path) && destination_path != '/'))
        puts 'Invalid params. Please double check them.'
        return false
      end
      true
    end

    private

    # returns array of pic_names to choose a background from, or false if we do not have enough pictures for a full 24hr rotation
    def full_24hrs_available
      prev_pic = ''
      sexy_pics = []

      Dir["#{data_path}/h_*.png"].sort { |x, y| y <=> x }.each do |pic|
        pic_time = pic[-8, 4]
        return sexy_pics if sexy_pics.count.positive? && pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic

        sexy_pics.unshift(pic) if sexy_pics.count.positive? || pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic
        prev_pic = pic_time
      end
      false
    end

    def init_paths(workdir)
      @app_root = workdir && File.directory?(workdir) ? workdir : Dir.pwd
      @work_path = @app_root
      @data_path = "#{@app_root}/data"

      @app_root = Pathname.new(File.expand_path(__dir__))
      Dir.mkdir(@data_path) unless File.exist?(@data_path)
    end

    def find_latest_local
      # we can't select by timestamp, because those could be messed up. Instead, just search for "latest" by filename
      # latest_pic = `ls -t #{data_path}/h_* | head -1`
      twodays_ago = now - 86_400 * 2
      latest = { timestamp: nil }
      failsafe = { filename: nil, timestamp: Time.new(twodays_ago.year, twodays_ago.month, twodays_ago.day, 0, 0, 0, '+00:00') }

      Dir["#{data_path}/h_*.png"].each do |pic|
        stamp = Time.parse("#{pic[0..-5].insert(-3, ':')}:00+00:00")
        `touch -t #{stamp.strftime('%Y%m%d%H%M.%S')} #{pic}`
        latest = { filename: pic, timestamp: stamp } if !latest[:timestamp] || latest[:timestamp] < stamp
      end

      latest[:timestamp] && latest[:timestamp] > twodays_ago ? latest : failsafe
    end
  end
end
