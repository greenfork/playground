class A
  W = 0
  X = 1
  Y = 2
  Z = 3
end

class Object
  U = -1
  Y = -2
end

class B < A
  X = 4
  Z = 5
end

class C < A
  Y = 6
end

class D
  Z = 7
end

class E < D
  W = 8
end
