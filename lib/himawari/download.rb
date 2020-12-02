# frozen-string-literal: true

module Himawari
  # Let's expand our basic Himawari class with the ability to actually download stuff
  # in addition to the downloading, we will also need to:
  #   - parse CLI arguments / set crontab (OsUtils)
  #   - check network status (NetUtils)
  #   - check and try to fix downloaded picture Tiles (Process)
  class Download < Base
    extend OsUtils
    include NetUtils
    include Process

    def start
      return false unless everything_ok

      set_background(latest_local[:filename], destination_path) if pics_updated? && mode == :live
      # clean up: remove any files that are more than 2 days old
      `find #{data_path} -name \"*.png\" -type f -mtime +2 -exec rm -f {} \\;`
    end

    def pics(from_datetime, to_datetime)
      # returns true if any new pictures were downloaded from the web, false otherwise
      pic_dwnlded = false
      from_datetime += 10 * 60 # +10.minutes from our latest pic on local drive

      while from_datetime <= to_datetime
        tenmin = if last_iter?(from_datetime, to_datetime)
                   OsUtils.tenmin(from_datetime.min, to_datetime.min)
                 elsif !pic_dwnlded # i.e. it's while's first iteration. don't update the whole hour, only the remaining minutes
                   OsUtils.tenmin(from_datetime.min)
                 else
                   OsUtils.tenmin
                 end

        pic_dwnlded = pic(from_datetime, tenmin)

        break if last_iter?(from_datetime, to_datetime) || !pic_dwnlded

        from_datetime = if to_datetime - from_datetime > 3600
                          from_datetime + 3600
                        else
                          Time.new(to_datetime.year, to_datetime.month, to_datetime.day, to_datetime.hour, 0, 0, '+00:00')
                        end
      end

      if verbose
        puts pic_dwnlded ? "Latest Fetched:  #{find_latest_local[:timestamp]}" : 'Nothing downloaded.'
      end
      pic_dwnlded
    end

    # `parallel --header : 'montage -mode concatenate -tile 2x {00,10,01,11}/{year}-{mo}-{dy}T{hr}{tenmin}000-*.png
    #  full/{year}-{mo}-{dy}T{hr}{tenmin}000.png' ::: year 2015 ::: mo 11 ::: dy {27..28} ::: hr {00..23} ::: tenmin {0..5}`
    def pic(timestamp, tenmin = '{0..5}')
      return false unless everything_ok

      if timestamp > latest_remote
        puts "Can't download #{timestamp} because it is newer than the most recent available (#{latest_remote})"
        return false
      end

      yr = timestamp.year.to_s.rjust(2, '0')
      mo = timestamp.month.to_s.rjust(2, '0')
      dy = timestamp.day.to_s.rjust(2, '0')
      hr = timestamp.hour.to_s.rjust(2, '0')
      x, y = download_region

      command1 = 'parallel -j5 --delay 0.1 --header : '\
                 "'curl -sC - \"#{HIMAWARI_URL}/"\
                 "#{resolution}d/550/{year}/{mo}/{dy}/{hr}{tenmin}000_{x}_{y}.png\" > "\
                 "#{data_path}/t_{year}-{mo}-{dy}T{hr}{tenmin}0-{y}_{x}.png'"\
                 " ::: year #{yr} ::: mo #{mo} ::: dy #{dy} ::: hr #{hr} ::: tenmin #{tenmin} ::: x #{x} ::: y #{y}"
      command2 = 'parallel --header : '\
                 "'montage -mode concatenate -tile #{resolution}x #{data_path}/t_{year}-{mo}-{dy}T{hr}{tenmin}0-*.png "\
                 "#{data_path}/h_{year}-{mo}-{dy}T{hr}{tenmin}0.png'"\
                 " ::: year #{yr} ::: mo #{mo} ::: dy #{dy} ::: hr #{hr} ::: tenmin #{tenmin}"
      # command3 = 'parallel convert -channel R -gamma 1.2 -channel G -gamma 1.1 +channel -sigmoidal-contrast 3,50% {} '\
      #            "pretty/{/} ::: #{data_path}/*.png"

      # system(command1) # works totally fine on mac...
      # OOOK>> I have NO idea why linux is not parsing {..} from parallel above and instead sticks it as a literal,
      # but we need to make it work >> hack it this way for the time being...
      script = "#{data_path}/script_#{yr}_#{yr}_#{mo}_#{dy}_#{hr}.sh"
      OsUtils.scriptify_sys(script, command1)

      check_tiles

      # system(command2) # works totally fine on mac...
      OsUtils.scriptify_sys(script, command2)
      `rm #{data_path}/t_*`
      true
    end

    private

    def everything_ok
      @everything_ok ||= params_valid? && checks_passed?
    end

    def checks_passed?
      if blacklisted_wifi?
        puts "Blacklisted Network; Won't go online"
        return false
      end

      # we don't want to spam himawari's site more than once every 10 minutes while running on a schedule
      return false if by_schedule && now.min % 10 != 1

      if `find #{data_path} -name \"t_*.png\"`.length.positive?
        puts 'Another himawari process is still downloading/processing files.\n' \
             '(There are tiles (t_*.png) in the `data` folder.) Quitting w/o overlapping.'
        return false
      end

      unless internet_connection?
        puts "Not online? Can't reach #{HIMAWARI_URL}"
        return false
      end
      true
    end

    def last_iter?(from, to)
      from.day == to.day && from.hour == to.hour
    end

    def pics_updated?
      pics(latest_local[:timestamp], latest_remote) unless up_to_date?
    end

    def download_region
      x = "{0..#{resolution - 1}}"
      y = if focus == :top # :full :mid :low
            "{0..#{(resolution / MONITOR_ASPECT).ceil - 1}}"
          elsif focus == :low
            "{#{resolution - (resolution / MONITOR_ASPECT).ceil}..#{resolution - 1}}"
          else # full / mid
            "{0..#{resolution - 1}}"
          end
      [x, y]
    end
  end
end
