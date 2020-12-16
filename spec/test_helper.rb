# frozen-string-literal: true

require 'minitest/autorun'
require_relative '../lib/himawari'

class HimawariTest < Minitest::Test
  # rubocop:disable Style/ClassVars
  @@workdir = Pathname.new(File.expand_path(__dir__))
  # rubocop:enable Style/ClassVars

  def setup
    @himawari = Himawari::Download
    date1 = Time.parse('2019-01-01 00:00:00 +00:00')
    date2 = Time.parse('2020-06-01 00:00:00 +00:00')
    @timestamp = Time.at((date2.to_f - date1.to_f) * rand + date1.to_f)

    # 1200secs == 20.minutes 02:40 and 14:40 are "bad" timestamps because
    # we know 100% that himawari does not take photos at those times
    @timestamp -= 1200 if @timestamp.min == 40 && [2, 14].include?(@timestamp.hour)
  end

  # def teardown
  #  puts 'run after each test'
  # end

  def capture_stdout
    original_stdout = $stdout  # capture previous value of $stdout
    $stdout = StringIO.new     # assign a string buffer to $stdout
    yield                      # perform the body of the user code
    $stdout.string             # return the contents of the string buffer
  ensure
    $stdout = original_stdout  # restore $stdout to its previous value
  end

  def self.cleanup
    puts "Cleanup: Removing #{@@workdir}/data"
    `ls -la #{@@workdir}/data && rm -r #{@@workdir}/data*` if File.directory?("#{@@workdir}/data")
  end
end

HimawariTest.cleanup
Minitest.after_run { HimawariTest.cleanup }
