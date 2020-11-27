require 'minitest/autorun'
require 'himawari'

class HimawariTest < Minitest::Test
  def test_english_hello
    assert_equal 'hello world', Himawari.get_pic
  end
end
