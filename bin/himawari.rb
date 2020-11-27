#!/usr/bin/env ruby

require 'himawari'

params = Himawari::OsUtils.parse_cli_args
Himawari.autorun(params)
