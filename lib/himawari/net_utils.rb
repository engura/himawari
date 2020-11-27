module Himawari
  module NetUtils
    private

    def blacklisted_wifi?
      current_wifi = if(OsUtils.os == :mac)
        `networksetup -getairportnetwork en0` # mac
      elsif(OsUtils.os == :linux)
        `iwgetid -r` # linux
      end
      puts current_wifi if verbose
      current_wifi && BLACK_LIST_WIFI.any? { |wifi| current_wifi.include?(wifi) }
    end

    def internet_connection?
      uid = now.to_i * 1_000
      begin
        r = HTTParty.get("#{HIMAWARI_URL}/latest.json?uid=#{uid}", { timeout: 10 })
        # puts "#{HIMAWARI_URL}/latest.json?uid=#{uid}" if verbose
        if r.code == 200
          puts "Latest Himawari: #{r['date']}" if verbose
          @latest_remote = Time.parse(r['date']+'+00:00')
          return true
        end
      rescue
        false
      end
      false
    end
  end
end
