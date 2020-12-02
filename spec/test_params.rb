# frozen-string-literal: true

require 'test_helper'

class TestParams < HimawariTest
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

  def capture_stdout
    original_stdout = $stdout  # capture previous value of $stdout
    $stdout = StringIO.new     # assign a string buffer to $stdout
    yield                      # perform the body of the user code
    $stdout.string             # return the contents of the string buffer
  ensure
    $stdout = original_stdout  # restore $stdout to its previous value
  end
end
