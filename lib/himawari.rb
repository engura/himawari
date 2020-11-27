#!/usr/bin/env ruby

require_relative './himawari/base.rb'
require_relative './himawari/os_utils.rb'
require_relative './himawari/net_utils.rb'
require_relative './himawari/process.rb'
require_relative './himawari/download.rb'

# encapsulates all the functions pertaining to acquiring images from the himawari8 satellite in near real-time
# from HIMAWARI_URL (defined in the Base Class)
module Himawari
  def self.autorun(params = {})
    Download.new(params).start
  end

  def self.get_pic(params = {})
    t = validate(params[:datetime])
    Download.new(params).pic(t, OsUtils.tenmin(t.min, t.min))
  end

  def self.get_pics(params = {})
    Download.new(params).pics(validate(params[:from]), validate(params[:to]))
  end

  def self.validate(stamp)
    return stamp if stamp.is_a? Time
    return Time.parse("#{stamp}+00:00") if stamp.is_a? String

    t = Time.now.utc - 600 # 600secs == 10.minutes ago
    Time.new(t.year, t.month, t.day, t.hour, t.min / 10 * 10, 0, '+00:00')
  end
end
