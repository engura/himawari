require 'httparty'
require 'fileutils'
require 'pathname'
require 'optparse'
# require 'pry'

module Himawari
  MONITOR_ASPECT = 16.0 / 9
  UPDATE_RATE = 2 # int; update the pic once every `UPDATE_RATE` minutes
  HIMAWARI_URL = 'https://himawari8-dl.nict.go.jp/himawari8/img/D531106'.freeze

  # Local (JST) midnight happens @14:10 UTC, so we have to use pics in interval of [2.days.ago@14:40 .. 1.day.ago@14:40]
  LOCAL_MIDNIGHT = '1410'.freeze

  # sets up the methods for Himawari that do not have to do with accessing the internet. ie:
  #   - it sets up all the default and customized params, builds awareness of the locally stored pics
  #   - implements "setting" the background (copies a downloaded image into a different folder)
  class Base
    attr_reader :now, :app_root, :work_path, :data_path, :destination_path, :focus, :mode, :resolution,
                :latest_local, :latest_remote, :verbose, :by_schedule, :blacklist_wifi

    # relative to the location of the script: Pathname.new(File.expand_path('../', __FILE__))
    # relative to the current working dir:    Dir.pwd
    def initialize(params)
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

      update_backgrnd if mode == :day
      OsUtils.crontab(cron_cmd, params[:cron]) if params[:cron]
    end

    def init_paths(workdir)
      @app_root = workdir || Dir.pwd
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
        stamp = Time.parse(pic[0..-5].insert(-3, ':') + ':00+00:00')
        `touch -t #{stamp.strftime('%Y%m%d%H%M.%S')} #{pic}`
        latest = { filename: pic, timestamp: stamp } if !latest[:timestamp] || latest[:timestamp] < stamp
      end

      latest[:timestamp] && latest[:timestamp] > twodays_ago ? latest : failsafe
    end

    def up_to_date?
      puts "Latest local:    #{latest_local[:timestamp]}" if verbose
      if now - latest_local[:timestamp] < 10 * 60
        puts 'Local pic is up to date; no need to go online.' if verbose
        return true
      end
      false
    end

    def set_background(img, destination_path)
      return unless destination_path
      return if destination_path == '/'

      cmd = "sleep 10 ; rm #{destination_path}/*.png ; cp #{img} #{destination_path}"
      # "osascript -e 'tell application \"System Events\" to tell DESKTOP to set picture to \"#{img}\"'"
      puts cmd if verbose
      system(cmd)
    end

    def update_backgrnd
      prev_pic = ''
      complete = false
      sexy_pics = []
      Dir["#{data_path}/h_*.png"].sort { |x, y| y <=> x }.each do |pic|
        pic_time = pic[-8, 4]
        if sexy_pics.count.positive? && pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic
          complete = true
          break
        end
        sexy_pics.unshift(pic) if sexy_pics.count.positive? || pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic
        prev_pic = pic_time
      end
      # puts sexy_pics
      # only rotate the background if we have one complete rotation of the globe saved
      return unless complete

      i = (now.hour * 60 + now.min) / UPDATE_RATE % sexy_pics.count
      puts "#{i} :: #{(now.hour * 60 + now.min)} % #{sexy_pics.count} switching to #{sexy_pics[i]}" if verbose
      set_background(sexy_pics[i], destination_path)
    end

    def cron_cmd
      '* * * * * PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin himawari ' \
      "-s -m #{mode} -f #{focus} -r #{resolution} -d '#{destination_path}' -w '#{work_path}'"
    end
  end
end
