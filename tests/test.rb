require 'minitest/autorun'
require 'himawari' 

class HimawariTest < Minitest::Test
  def test_english_hello
    assert_equal "hello world",
      Hola.hi("english")
  end

  def test_spanish_hello
    assert_equal "hola mundo",
      Hola.hi("spanish")
  end
end
