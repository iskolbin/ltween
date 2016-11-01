local sin, cos, pi, pi_2, sqrt, unpack = math.sin, math.cos, math.pi, math.pi / 2, math.sqrt, table.unpack or _G.unpack

-- From http://www.gizma.com/easing/
-- t -- current time
-- b -- start value
-- c -- change in value
-- d -- duration
local tween = {}

-- After stop action
function tween.STOP() return tween.STOP end -- Do nothing (default)
function tween.RESET() return tween.RESET end -- Call update function with start parameter
function tween.PONG() return tween.PONG end	-- Loop from end to start, from start to end and so forth
function tween.LOOP() return tween.LOOP end	-- Loop from start to end, reseting each time

-- step tweening - zero until time >= duration
function tween.STEP( t, b, c, d )
	return b + ((t >= d) and c or 0)
end

-- simple linear tweening - no easing, no acceleration
function tween.LINEAR( t, b, c, d ) 
	return c * t / d + b
end

-- quadratic easing in - accelerating from zero velocity
function tween.IN( t, b, c, d ) 
	t = t / d
	return c * t * t + b
end

-- quadratic easing out - decelerating to zero velocity
function tween.OUT( t, b, c, d )
	t = t / d
	return -c * t * (t - 2) + b
end

-- quadratic easing in/out - acceleration until halfway, then deceleration
function tween.IN_OUT( t, b, c, d ) 
	t = 2 * t / d
	if t < 1 then return 0.5 * c * t * t + b end
	t = t - 1
	return - 0.5 * c * ( t * ( t - 2 ) - 1 ) + b
end

-- cubic easing in - accelerating from zero velocity
function tween.IN_3( t, b, c, d )
	t = t / d
	return c * t * t * t + b
end

-- cubic easing out - decelerating to zero velocity
function tween.OUT_3( t, b, c, d ) 
	t = t / d
	t = t - 1
	return c * ( t * t * t  + 1) + b
end

-- cubic easing in/out - acceleration until halfway, then deceleration
function tween.IN_OUT_3( t, b, c, d ) 
	t = 2 * t / d
	if (t < 1) then return 0.5 * c * t * t * t + b end
	t = t - 2
	return 0.5 * c * ( t * t * t + 2) + b
end

-- sinusoidal easing in - accelerating from zero velocity
function tween.IN_SIN( t, b, c, d ) 
	return -c * cos(t / d * (pi_2)) + c + b
end

-- sinusoidal easing out - decelerating to zero velocity
function tween.OUT_SIN( t, b, c, d ) 
	return c * sin( t / d * ( pi_2 )) + b
end

-- sinusoidal easing in/out - accelerating until halfway, then decelerating
function tween.IN_OUT_SIN( t, b, c, d ) 
	return -0.5 * c * (cos( pi * t / d ) - 1) + b
end

-- exponential easing in - accelerating from zero velocity
function tween.IN_EXP( t, b, c, d ) 
	return c * 2 ^ ( 10 * (t/d - 1) ) + b
end

-- exponential easing out - decelerating to zero velocity
function tween.OUT_EXP( t, b, c, d ) 
	return c * ( -2 ^ (-10 * t/d ) + 1 ) + b
end

-- exponential easing in/out - accelerating until halfway, then decelerating
function tween.IN_OUT_EXP( t, b, c, d ) 
	t = 2 * t / d
	if t < 1 then return 0.5 * c * 2 ^ (10 * (t - 1) ) + b end
	t = t - 1
	return 0.5 * c * ( -2 ^ (-10 * t) + 2 ) + b
end

-- circular easing in - accelerating from zero velocity
function tween.IN_CIR( t, b, c, d ) 
	t = t / d
	return -c * (sqrt( 1 - t * t ) - 1) + b
end

-- circular easing out - decelerating to zero velocity
function tween.OUT_CIR( t, b, c, d ) 
	t = t / d
	t = t - 1
	return c * sqrt( 1 - t * t ) + b
end

-- circular easing in/out - acceleration until halfway, then deceleration
function tween.IN_OUT_CIR( t, b, c, d ) 
	t = 2 * t / d
	if t < 1 then return -0.5 * c * ( sqrt(1 - t * t) - 1 ) + b end
	t = t - 2
	return 0.5 * c * ( sqrt(1 - t * t) + 1) + b
end

local TweenPool = {}

TweenPool.__index = TweenPool

function TweenPool.new( clock )
	return setmetatable( {
		_clock = clock or 0,
		_tweens = {},
		_toremove = {},
	}, TweenPool )
end

function TweenPool:anim( start, target, length, ease, update, callback, ... )
	assert( start, 'Start value -- first arg -- is not set' )
	assert( target, 'Target value -- second arg -- is not set' )
	assert( length, 'Length -- third arg -- is not set, should be number(seconds to finish tween)' )
	assert( ease, 'Easing mode -- fourth arg -- is not set, should be tween.STEP/LINEAR/IN/OUT/IN_OUT/etc.' )
	assert( update, 'Updater -- fifth arg -- is not set, should be callable' )

	local twn = {}
	twn.start = start
	twn.target = target
	twn.length = length
	twn.update = update 
	twn.ease = ease
	twn.callback = callback
	twn.args = callback and ( select('#',...) > 0 and {...} )
	
	local index = #self._tweens + 1
	twn.startclock = self._clock
	twn.index = index
	
	self._tweens[index] = twn

	return twn
end

function TweenPool:remove( twn )
	table.insert( self._toremove, twn )
end

function TweenPool:contains( twn )
	return twn and self._tweens[twn.index] == twn
end

function TweenPool:flush()
	local tweens = self._tweens
	local toremove = self._toremove
	for i = 1, #toremove do
		local twn = toremove[i]
		local index = twn.index
		if tweens[index] == twn then
			local n = #tweens
			if index ~= n then
				tweens[index] = tweens[n]
				tweens[index].index = index
			end
			tweens[n] = nil
		end
		toremove[i] = nil
	end
end

function TweenPool:update( dt )
	self:flush()
	
	self._clock = self._clock + dt

	local currentclock = self._clock

	local tweens = self._tweens
	for i = 1, #tweens do
		local twn = tweens[i] 
		local startclock = twn.startclock
		local t, b, c, d = currentclock - startclock, twn.start, twn.target - twn.start, twn.length
		
		if t >= d then
			twn:update( twn.target )

			local mode
			if twn.callback then
				mode = twn:callback( twn.args and unpack( twn.args ))
			end

			if mode == tween.PONG then
				twn.clock = currentclock
				twn.target, twn.start = twn.start, twn.target

			elseif mode == tween.LOOP then
				twn.startclock = currentclock

			else
				if mode == tween.RESET then
					twn:update( twn.start )
				end
				self:remove( twn )
			end
		else
			twn:update( twn.ease( t, b, c, d ))
		end
	end
end

function TweenPool:reset( clock )
	self:flush()

	local dt = clock - self._clock
	self._clock = clock

	for i = 1, #tween do
		tween.startclock = tween.startclock + dt
	end
end

tween.TweenPool = setmetatable( TweenPool, { __call = function(_,...)
	return TweenPool.new( ... )
end } )

tween._defaultpool = TweenPool()

function tween.anim( ... )
	return tween._defaultpool:anim( ... )
end

function tween.update( ... )
	return tween._defaultpool:update( ... )
end

function tween.remove( ... )
	return tween._defaultpool:remove( ... )
end

function tween.reset( ... )
	return tween._defaultpool:reset( ... )
end

return tween
