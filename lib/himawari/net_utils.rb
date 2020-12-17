# frozen-string-literal: true

module Himawari
  # Network-related methods to help establish whether there is network access and
  # figure out if we are on a possibly "metered" connection (via a hard-coded SSID blacklist)
  module NetUtils
    # Checks our connection and as a bonus...
    # @return [DateTime] timestamp of the latest himawari image; also as a side-efffect:
    #    true, false whether we even have connection to the website
    def internet_connection?
      uid = now.to_i * 1_000
      r = HTTParty.get("#{HIMAWARI_URL}/latest.json?uid=#{uid}", { timeout: 10 })
      # puts "#{HIMAWARI_URL}/latest.json?uid=#{uid}" if verbose
      if r.code == 200
        puts "Latest Himawari: #{r['date']}" if verbose
        @latest_remote = Time.parse("#{r['date']}+00:00")
        return true
      end
      false
    end

    private

    # Sometimes we don't want to use a particular network to download large amounts of data...
    # @return [true, false] whether the current (wifi) network is blacklisted in the blacklist_wifi [Array]
    def blacklisted_wifi?
      current_wifi = case OsUtils.os
                     when :mac
                       `networksetup -getairportnetwork en0`
                     when :linux
                       `iwgetid -r`
                     end
      puts current_wifi if verbose
      current_wifi && blacklist_wifi.any? { |wifi| current_wifi.include?(wifi) }
    end
  end
end
