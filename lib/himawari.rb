# frozen-string-literal: true

require_relative './himawari/base'
require_relative './himawari/os_utils'
require_relative './himawari/net_utils'
require_relative './himawari/process'
require_relative './himawari/download'

# encapsulates all the functions pertaining to acquiring images from the himawari8 satellite in near real-time
# from HIMAWARI_URL (defined in the Base Class)
module Himawari
  # all-in-one method. downloads images, sets backgrounds, crontabs, whatever
  # @param params [Hash] any combination of the acceptable command line args you can throw at it.
  #    Plz see README for the list/description
  # @return nothing useful
  def self.autorun(params = {})
    h = Download.new(params)
    h.cron_action ? h.crontab : h.update_backgrnd ^ h.start
  end

  # downloads 1 picture from himawari website, closest (but in the past of) the `:datetime` provided in the params
  # @param [Hash] any combination of the acceptable command line args + THE REQUIRED `:datetime` additional stamp
  # @return [true, false] on success/failure
  def self.get_pic(params = {})
    t = validate(params[:datetime])
    Download.new(params).pic(t, OsUtils.tenmin(t.min, t.min))
  end

  # downloads many pictures from himawari website, in the range of [:from, :to] provided in the params
  # @param [Hash] any combination of the acceptable command line args + THE REQUIRED `:from` && `:to` timestamps
  # @return [true, false] on success/failure
  def self.get_pics(params = {})
    Download.new(params).pics(validate(params[:from]), validate(params[:to]))
  end

  # validates the user-provided timestamps coming from `get_pic` or `get_pics` methods
  # @param stamp [DateTime, String]
  # @return [DateTime] of the stamp, or the most recent round 10-minute mark to Time.now - 10.minutes
  def self.validate(stamp)
    return stamp if stamp.is_a? Time
    return Time.parse("#{stamp}+00:00") if stamp.is_a? String

    t = Time.now.utc - 600 # 600secs == 10.minutes ago
    Time.new(t.year, t.month, t.day, t.hour, t.min / 10 * 10, 0, '+00:00')
  end
end
