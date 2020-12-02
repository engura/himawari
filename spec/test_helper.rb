# frozen-string-literal: true

require 'minitest/autorun'
require 'himawari'

class HimawariTest < Minitest::Test
  # rubocop:disable Style/ClassVars
  @@workdir = Pathname.new(File.expand_path(__dir__))
  # rubocop:enable Style/ClassVars

  def setup
    @himawari = Himawari::Download
  end

  # def teardown
  #  puts 'run after each test'
  # end
  def self.cleanup
    puts "After Test Cleanup. Will remove #{@@workdir}"
    `rm -r #{@@workdir}/data*`
  end
end

Minitest.after_run { HimawariTest.cleanup }
