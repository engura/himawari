module Himawari
  class Download < Base
    extend OsUtils
    include NetUtils
    include Process

    def start
      if blacklisted_wifi?
        puts "Blacklisted Network; Won't go online"
        return
      end

      if `find #{data_path} -name \"t_*.png\"`.length > 0
        puts "Another himawari process is still downloading/processing files. Quitting w/o overlapping."
        return
      end

      if !internet_connection?
        puts "Not online. Can't update"
        return
      end

      set_background(latest_local[:filename], destination_path) if pics_updated? && mode == :live
      # clean up: remove any files that are more than 2 days old
      `find #{data_path} -name \"*.png\" -type f -mtime +2 -exec rm -f {} \\;`
    end

    def pics(from_datetime, to_datetime)
      # returns true if any new pictures were downloaded from the web, false otherwise
      pic_changed = false
      from_datetime += 10 * 60 # +10.minutes
      # puts "Modified latest_local:  #{latest_local[:timestamp]}"

      while from_datetime <= to_datetime
        tenmin = if from_datetime.day == to_datetime.day && from_datetime.hour == to_datetime.hour
          "{#{from_datetime.min / 10}..#{to_datetime.min / 10}}"
        elsif !pic_changed # i.e. it's while's first iteration. don't update the whole hour, only the remaining minutes
          "{#{from_datetime.min / 10}..5}"
        else
          '{0..5}'
        end
        pic_changed = true

        pic(from_datetime, tenmin)
        break if from_datetime.day == to_datetime.day && from_datetime.hour == to_datetime.hour
        from_datetime = if to_datetime - from_datetime > 3600
          from_datetime + 3600
        else
          Time.new(to_datetime.year, to_datetime.month, to_datetime.day, to_datetime.hour, 0, 0, '+00:00')
        end
      end

      puts pic_changed ? "Latest Fetched:  #{find_latest_local()[:timestamp]}" : "We are up to date with Himawari. Nothing downloaded."
      pic_changed
    end

    # `parallel --header : 'montage -mode concatenate -tile 2x {00,10,01,11}/{year}-{mo}-{dy}T{hr}{tenmin}000-*.png full/{year}-{mo}-{dy}T{hr}{tenmin}000.png' ::: year 2015 ::: mo 11 ::: dy {27..28} ::: hr {00..23} ::: tenmin {0..5}`
    def pic(timestamp, tenmin = '{0..5}')
      yr = timestamp.year.to_s.rjust(2, '0')
      mo = timestamp.month.to_s.rjust(2, '0')
      dy = timestamp.day.to_s.rjust(2, '0')
      hr = timestamp.hour.to_s.rjust(2, '0')

      x = "{0..#{resolution - 1}}"
      y = if focus == :top # :full :mid :low
        "{0..#{(resolution / MONITOR_ASPECT).ceil - 1}}"
      elsif focus == :low
        "{#{resolution - (resolution / MONITOR_ASPECT).ceil}..#{resolution - 1}}"
      else # full / mid
        "{0..#{resolution - 1}}"
      end

      command1 = "parallel -j5 --delay 0.1 --header : "\
                 "'curl -sC - \"#{HIMAWARI_URL}/"\
                 "#{resolution}d/550/{year}/{mo}/{dy}/{hr}{tenmin}000_{x}_{y}.png\" > #{data_path}/t_{year}-{mo}-{dy}T{hr}{tenmin}0-{y}_{x}.png'"\
                 " ::: year #{yr} ::: mo #{mo} ::: dy #{dy} ::: hr #{hr} ::: tenmin #{tenmin} ::: x #{x} ::: y #{y}"
      command2 = "parallel --header : "\
                 "'montage -mode concatenate -tile #{resolution}x #{data_path}/t_{year}-{mo}-{dy}T{hr}{tenmin}0-*.png #{data_path}/h_{year}-{mo}-{dy}T{hr}{tenmin}0.png'"\
                 " ::: year #{yr} ::: mo #{mo} ::: dy #{dy} ::: hr #{hr} ::: tenmin #{tenmin}"
      command3 = "parallel convert -channel R -gamma 1.2 -channel G -gamma 1.1 +channel -sigmoidal-contrast 3,50% {} pretty/{/} ::: #{data_path}/*.png"

      #system(command1) # works totally fine on mac...
      # OOOK>> I have NO idea why linux is not parsing {..} from parallel above and instead sticks it as a literal, but we need to make it work>> hack it this way for the time being...
      script = "#{app_root}/script_#{yr}_#{yr}_#{mo}_#{dy}_#{hr}.sh"
      OsUtils.scriptify_sys(script, command1)

      control_size = File.size("#{app_root}/no_image.png")
      bad_tiles = {}
      Dir["#{data_path}/t_*.png"].each do |tile|
        bad_tiles = process_bad_tiles(bad_tiles, tile) if File.size(tile) == control_size && system("cmp #{tile} #{app_root}/no_image.png")
      end
      recover_bad_sectors(bad_tiles)

      #system(command2) # works totally fine on mac...
      OsUtils.scriptify_sys(script, command2)
      `rm #{data_path}/t_*`
    end

    private

    def pics_updated?
      pics(latest_local[:timestamp], latest_remote) if not up_to_date?
    end
  end
end
