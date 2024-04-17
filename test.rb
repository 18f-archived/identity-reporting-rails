require 'pp'

def foobar(arg, **splat)
  [arg, splat]
end

pp RUBY_VERSION
pp foobar(1, { a: 1 })
