local TweenPool = require'TweenPool'

assert( getmetatable( TweenPool()) == TweenPool )
assert( getmetatable( TweenPool.new()) == TweenPool )

