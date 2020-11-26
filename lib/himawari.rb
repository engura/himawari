#!/usr/bin/env ruby

require_relative './himawari/base.rb'
require_relative './himawari/os_utils.rb'
require_relative './himawari/net_utils.rb'
require_relative './himawari/process.rb'
require_relative './himawari/download.rb'

module Himawari
  def self.start(params)
    Download.new(params).start
  end
end

params = Himawari::OsUtils.parse_cli_args
p params
Himawari.start(params)
