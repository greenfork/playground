class Example
  def test
    puts 'test'
  end
end

module Aspect
  def test
    puts "before"
    super
    puts "after"
  end
end

Example.prepend(Aspect)

element = Example.new
element.test
