require 'httparty'
require 'fileutils'
require 'pathname'
require 'optparse'
# require 'pry'

module Himawari
  MONITOR_ASPECT = 16.0 / 9
  UPDATE_RATE = 2 # int; update the pic once every `UPDATE_RATE` minutes
  HIMAWARI_URL = "https://himawari8-dl.nict.go.jp/himawari8/img/D531106"

  # Local (JST) midnight happens @14:10 UTC, so we have to use pics in interval of [2.days.ago@14:40 .. 1.day.ago@14:40]
  LOCAL_MIDNIGHT = '1410'
  BLACK_LIST_WIFI = %w[XperiaX]

  class Base
    attr_reader :now, :app_root, :data_path, :destination_path, :focus, :mode, :resolution,
                :latest_local, :latest_remote

    def initialize(params)
      @now = Time.now.utc
      @app_root = params[:workdir]
      @data_path = "#{@app_root}/data"
      @destination_path = params[:destination]
      @focus = params[:focus]
      @mode = params[:mode]
      @resolution = params[:resolution]
      Dir.mkdir(@data_path) unless File.exists?(@data_path)
      @latest_local = find_latest_local
      @latest_remote = nil

      update_backgrnd if mode == :day
      OsUtils.crontab(cron_cmd, params[:cron]) if params[:cron]
    end

    def find_latest_local
      # we can't select by timestamp, because those could be messed up. Instead, just search for "latest" by filename
      # latest_pic = `ls -t #{data_path}/h_* | head -1`
      twodays_ago = Time.now.utc - 86400 * 2
      latest = { timestamp: nil }
      failsafe = { filename: nil, timestamp: Time.new(twodays_ago.year, twodays_ago.month, twodays_ago.day, 0, 0, 0, '+00:00') }

      Dir["#{data_path}/h_*.png"].each do |pic|
        begin
          stamp = Time.parse(pic[0..-5].insert(-3, ':') + ':00+00:00')
          `touch -t #{stamp.strftime('%Y%m%d%H%M.%S')} #{pic}`
          latest = { filename: pic, timestamp: stamp } if !latest[:timestamp] || latest[:timestamp] < stamp
        rescue
          puts "Error: could not derive timestamp from filename of `#{pic}`"
        end
      end

      latest[:timestamp] && latest[:timestamp] > twodays_ago ? latest : failsafe
    end

    def up_to_date?
      puts "Latest local:    #{latest_local[:timestamp]}"
      if now - latest_local[:timestamp] < 10 * 60 # || now.min % 10 != 1
        puts "Local pic is up to date; no need to go online."
        exit
      end
    end

    def set_background(img, destination_path = nil)
      cmd = if destination_path
        "sleep 10 ; rm #{destination_path}/*.png ; cp #{img} #{destination_path}"
      else
        "osascript -e 'tell application \"System Events\" to tell DESKTOP to set picture to \"#{img}\"'"
      end
      puts cmd
      system(cmd)
    end

    def update_backgrnd
      now = Time.now.utc
      prev_pic = ''
      complete = false
      sexy_pics = []
      Dir["#{data_path}/h_*.png"].sort { |x, y| y <=> x }.each do |pic|
        pic_time = pic[-8, 4]
        if sexy_pics.count > 0 && pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic
          complete = true
          break
        end
        sexy_pics.unshift(pic) if sexy_pics.count > 0 || pic_time < LOCAL_MIDNIGHT && LOCAL_MIDNIGHT <= prev_pic
        prev_pic = pic_time
      end
      # puts sexy_pics

      if complete # only rotate the background if we have one complete rotation of the globe saved
        i = (now.hour * 60 + now.min) / UPDATE_RATE % sexy_pics.count
        puts "#{i} :: #{(now.hour * 60 + now.min)} % #{sexy_pics.count} switching to #{sexy_pics[i]}"
        set_background(sexy_pics[i], destination_path)
      end
    end

    def cron_cmd
      "* * * * * himawari -#{mode} -f #{focus} -r #{resolution} -d '#{destination_path}'"
    end
  end
end
