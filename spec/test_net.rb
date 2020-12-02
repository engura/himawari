# frozen-string-literal: true

require 'test_helper'

class TestNet < HimawariTest
  # Do the main methods function w/o crashing?
  def test_get_pic
    assert_equal true, Himawari.get_pic(datetime: '2020-06-01 01:30:00', workdir: @@workdir)
  end

  def test_get_pics
    puts 'test_get_pics'
    # assert_equal true, Himawari.get_pics(from: '2020-06-01 05:00:00', to: '2020-06-01 10:00:00', workdir: @@workdir)
  end
end
