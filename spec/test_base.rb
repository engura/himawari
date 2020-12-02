# frozen-string-literal: true

require 'test_helper'

class TestBase < HimawariTest
  # Firstly, let's check our params sanity...
  def test_bad_params
    bad_params = [
      { resolution: 5 },
      { focus: :bad },
      { mode: 'live' },
      { blacklist: 'live' },
      { destination: '/definitely/a/bad_path' }
    ]
    bad_combos = (1..bad_params.count).flat_map { |length| bad_params.combination(length).to_a }

    bad_combos.each do |params|
      params = (params + [{ workdir: @@workdir }]).reduce({}, :merge)

      # out = \
      capture_stdout do
        puts params
        assert_equal false, @himawari.new(params).params_valid?
      end
      # puts out
    end
  end

  def test_up_to_date
    h = @himawari.new({ workdir: @@workdir })
    assert_equal false, h.up_to_date?

    h.latest_local[:timestamp] = Time.now - 300 # 300 == 5.minutes
    assert_equal true, h.up_to_date?
  end

  def test_set_background
    destination = "#{@@workdir}/data/selected_background"
    Dir.mkdir(destination) unless File.exist?(destination)

    h = @himawari.new({ workdir: @@workdir, destination: destination })
    sample = Dir["#{h.data_path}/h_*.png"].sample

    assert_equal !sample.nil?, h.background(sample)
  end

  def test_cron
    cmd = @himawari.new({ workdir: @@workdir }).crontab(:set)
    assert_equal true, `crontab -l | grep \"#{cmd}\"`.size.positive?

    @himawari.new({ workdir: @@workdir }).crontab(:clear)
    assert_equal true, `crontab -l | grep \"#{cmd}\"`.empty?
  end
end
