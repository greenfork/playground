module A
  def a = puts "a"
end

class B
  private
   include A
end

B.new.a()
