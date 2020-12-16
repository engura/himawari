# frozen-string-literal: true

require 'test_helper'

class TestNet < HimawariTest
  # Do the main methods function w/o crashing?
  def test_get_pic
    puts "Try to get a pic from #{@timestamp}"
    assert_equal true, Himawari.get_pic(datetime: @timestamp, workdir: @@workdir)
  end

  def test_get_pic_blacklisted_wifi
    current_wifi = case Himawari::OsUtils.os
                   when :mac
                     `networksetup -getairportnetwork en0`
                   when :linux
                     `iwgetid -r`
                   end

    capture_stdout do
      assert_equal false, Himawari.get_pic(datetime: @timestamp, workdir: @@workdir, blacklist: [current_wifi])
    end
  end

  def test_get_pics
    puts "Try to get pics in #{@timestamp} ~ #{@timestamp + 3600 * 2}"
    assert_equal true, Himawari.get_pics(from: @timestamp, to: @timestamp + 3600 * 2, workdir: @@workdir)
  end
end
