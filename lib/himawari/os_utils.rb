# frozen-string-literal: true

module Himawari
  # all the misc. functions for dealing with CLI and/or OS...
  module OsUtils
    # we gotta know what the user's OS is! (because we rely on command line utils to process images)
    # @return [Symbol] representing the OS being used
    def self.os
      case RUBY_PLATFORM
      when /win32/
        :win
      when /linux/
        :linux
      when /darwin/
        :mac
      when /freebsd/
        :freebsd
      else
        :unknown
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/BlockLength
    # This is just a list of args that the CLI can accept
    # @return [Hash] of cleaned/verified params
    def self.parse_cli_args
      params = {}

      OptionParser.new do |opts|
        opts.banner = 'Usage: himawari [params]'

        opts.on('-f', '--focus STRING', String, 'Which section of the planet to focus on? ' \
                                                'Valid values are `full`, `top`, `mid`, `low`. Default is `top`.') do |o|
          params[:focus] = o.to_sym if %w[full top mid low].include? o
        end

        opts.on('-m', '--mode STRING', String, 'Valid values are `day` (cycles pics in the `destination` folder from the' \
                                               'most recent day) or `live` (copies the latest photo downloaded ' \
                                               'to `destination`) Default is `day`.') do |o|
          params[:mode] = :live if o == 'live'
        end

        opts.on('-r', '--resolution INT', Integer, 'Adjust the resolution of the downloaded image. Valid numbers are ' \
                                                   '2, 4, 8, 16, 20. 20 is the highest resolution and 2 is the default. ' \
                                                   'For a 4k-monitor a setting of 4 seems sufficient.') do |o|
          params[:resolution] = o if o <= 20 && o.positive? && o.even?
        end

        opts.on('-d', '--destination PATH', String, 'The folder where to copy a background image. If left blank, images will ' \
                                                    'just be downloaded, but won\'t be copied anywhere afterward.') do |o|
          params[:destination] = o if File.directory?(o)
        end

        opts.on('-w', '--workdir PATH', String, 'The folder where to save all the downloaded pics. If left blank, ' \
                                                'images will be saved to the `./data` directory relative to your ' \
                                                'current path of working dir.') do |o|
          params[:workdir] = o if File.directory?(o)
        end

        opts.on('-b', '--blacklist STRING,STRING...', Array, 'Blacklist SSIDs of networks from which we do not want to go ' \
                                                             'online to download new images.') do |o|
          params[:blacklist] = o
        end

        opts.on('-c', '--cron STRING', String, 'Can `set`/`clear` cron with the specified params, so we can update the images ' \
                                               'automatically') do |o|
          params[:cron] = o.to_sym if %w[set clear].include? o
        end

        opts.on('-v', '--verbose', 'Increase verbosity: mostly for debugging') do |o|
          params[:verbose] = o
        end

        opts.on('-s', '--schedule', 'Flag for determining when the script is run by schedule/automatically.') do |o|
          params[:by_schedule] = o
        end

        opts.on('-h', '--help', 'Prints this help & exits') do
          puts opts
          exit
        end
      end.parse! # (into: params)

      params
    end
    # rubocop:enable Metrics/MethodLength, Metrics/BlockLength

    # Ok, this is a weird method. On Mac, `script` just ran normally through ruby. But, on linux...
    # It is refusing to interpolate variables within the `script` string properly.
    # So, we'll make a temporary bash script, execute it, and then delete it.
    # @param script [String] the temp script's filename
    # @param command [String] what we actually want to be done... (probably process pics in parallel)
    # @return nothing useful (true on success)
    def self.scriptify_sys(script, command)
      `echo "#!/bin/bash\n#{command}" > #{script}`
      `chmod +x #{script} && #{script}`
      `rm #{script}`
    end

    # tiny helper method. converts normal minutes into the closest (floored) round ten-minutes.
    # (ie like 10, 20, 30, 40, 50). Himawari website uses these in the tile filenames...
    # @param from [Integer]
    # @param to [Integer] these should be pretty self-explanatory. should be positive and w/in 0-59 range.
    # @return [String] the formatted minute range string for `parallel` to use to download this range of pics
    def self.tenmin(from = 0, to = 59)
      "{#{from / 10}..#{to / 10}}"
    end

    # to force crossfade:
    # https://apple.stackexchange.com/questions/141834/applescript-to-change-desktop-image-on-all-monitors

    # set picture rotation to 1 -- turn on wallpaper cycling
    # set change interval to -1 -- force a change to happen right now
    # delay 1.5 -- wait a bit to allow for the fade transition - you may want to play w/ this #
    # set picture of item N of theDesktops to POSIX file ("/Users/vladimir/chie/lib/space/data/h_2019-11-06T0220.png")
    #   -- set wallpaper to wallpaper you want
    # set picture rotation to 0  -- turn off wallpaper cycling

    # tell application "System Events"
    #     tell every desktop
    #     tell desktop 1
    #         set pictures folder to "/Library/Desktop Pictures"
    #         set picture rotation to 2 -- using interval
    #         set change interval to 1800
    #         set random order to true
    #     end tell
    #     tell desktop 2
    #         set pictures folder to "/Library/Desktop Pictures/Mine"
    #         set picture rotation to 2 -- using interval
    #         set change interval to 1800
    #         set random order to true
    #     end tell
    # end tell

    # to silence the status mails, add MAILTO='' at the top of the crontab manually
    # Sets or clears the crontab!
    # @param cmd [String] the himawari script + all the passed args for it
    # @param action [Symbol] what to do? :set the cron? or :clear the cron?
    # @return nothing useful
    def self.crontab(cmd, action)
      if action == :set
        `(crontab -l ; echo \"#{cmd}\") 2>&1 | grep -v \"no crontab\" | sort | uniq | crontab -`
      else
        `(crontab -l ; echo \"#{cmd}\") 2>&1 | grep -v \"no crontab\" | grep -v himawari | sort | uniq | crontab -`
      end
    end
  end
end
