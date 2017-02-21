--[[

 tween -- v0.2.6 public domain Lua tweening library
 no warranty implied; use at your own risk
 
 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/timer

 Library uses easing functions gathered from http://www.gizma.com/easing/

 COMPATIBILITY

 Lua 5.1, 5.2, 5.3, LuaJIT 1, 2

 LICENSE

 This software is dual-licensed to the public domain and under the following
 license: you are granted a perpetual, irrevocable license to copy, modify,
 publish, and distribute this file as you see fit.

--]]

local sin, cos, pi, pi_2, sqrt, unpack = math.sin, math.cos, math.pi, math.pi / 2, math.sqrt, table.unpack or _G.unpack

-- t -- current time
-- b -- start value
-- c -- change in value
-- d -- duration
local TweenPool = {
	-- step tweening - zero until time >= duration
	STEP = function( t, b, c, d ) return b + ((t >= d) and c or 0) end,
	
	-- linear easing -- no acceleration
	LINEAR = function( t, b, c, d ) return c * t / d + b end,

	-- quadratic easing in - accelerating from zero velocity
	IN = function( t, b, c, d ) local t1 = t / d; return c * t1 * t1 + b end,

	-- quadratic easing out - decelerating to zero velocity
	OUT = function( t, b, c, d ) local t1 = t / d; return -c * t1 * (t1 - 2) + b end,

	-- quadratic easing in/out - acceleration until halfway, then deceleration
	IN_OUT = function( t, b, c, d ) 
		t = 2 * t / d
		if t < 1 then return 0.5 * c * t * t + b end
		t = t - 1
		return - 0.5 * c * ( t * ( t - 2 ) - 1 ) + b
	end,

	-- cubic easing in - accelerating from zero velocity
	IN_3 = function( t, b, c, d ) local t1 = t / d; return c * t1 * t1 * t1 + b end,

	-- cubic easing out - decelerating to zero velocity
	OUT_3 = function( t, b, c, d ) local t1 = t / d; local t2 = t - 1; return c * ( t2 * t2 * t2  + 1) + b end,

	-- cubic easing in/out - acceleration until halfway, then deceleration
	IN_OUT_3 = function( t, b, c, d ) 
		t = 2 * t / d
		if (t < 1) then return 0.5 * c * t * t * t + b end
		t = t - 2
		return 0.5 * c * ( t * t * t + 2) + b
	end,

	-- sinusoidal easing in - accelerating from zero velocity
	IN_SIN = function( t, b, c, d ) return -c * cos(t / d * (pi_2)) + c + b end,

	-- sinusoidal easing out - decelerating to zero velocity
	OUT_SIN = function( t, b, c, d ) return c * sin( t / d * ( pi_2 )) + b end,

	-- sinusoidal easing in/out - accelerating until halfway, then decelerating
	IN_OUT_SIN = function( t, b, c, d ) return -0.5 * c * (cos( pi * t / d ) - 1) + b end,

	-- exponential easing in - accelerating from zero velocity
	IN_EXP = function( t, b, c, d ) return c * 2 ^ ( 10 * (t/d - 1) ) + b end,

	-- exponential easing out - decelerating to zero velocity
	OUT_EXP = function( t, b, c, d )  return c * ( -2 ^ (-10 * t/d ) + 1 ) + b end,

	-- exponential easing in/out - accelerating until halfway, then decelerating
	IN_OUT_EXP = function( t, b, c, d ) 
		t = 2 * t / d
		if t < 1 then return 0.5 * c * 2 ^ (10 * (t - 1) ) + b end
		t = t - 1
		return 0.5 * c * ( -2 ^ (-10 * t) + 2 ) + b
	end,

	-- circular easing in - accelerating from zero velocity
	IN_CIR = function( t, b, c, d )  local t1 = t / d; return -c * (sqrt( 1 - t1 * t1 ) - 1) + b end,

	-- circular easing out - decelerating to zero velocity
	OUT_CIR = function( t, b, c, d ) local t1 = t / d; local t2 = t - 1; return c * sqrt( 1 - t2 * t2 ) + b end,

	-- circular easing in/out - acceleration until halfway, then deceleration
	IN_OUT_CIR = function( t, b, c, d ) 
		t = 2 * t / d
		if t < 1 then return -0.5 * c * ( sqrt(1 - t * t) - 1 ) + b end
		t = t - 2
		return 0.5 * c * ( sqrt(1 - t * t) + 1) + b
	end,

	-- Errors
	ERROR_BAD_START = 'First argument (start) is not set',
	ERROR_BAD_TARGET = 'Second argument (target) is not set',
	ERROR_BAD_LENGTH = 'Third argument (length) is not set',
	ERROR_BAD_EASING = 'Fourth argument (easing function) is not set',
	ERROR_BAD_UPDATER = 'Fifth argument (updater function) is not set',
	ERROR_NIL_TWEEN = 'Tween is nil',
}

-- After stop action
function TweenPool.STOP() return TweenPool.STOP end -- Do nothing (default)
function TweenPool.RESET() return TweenPool.RESET end -- Call update function with start parameter
function TweenPool.PONG() return TweenPool.PONG end	-- Loop from end to start, from start to end and so forth
function TweenPool.LOOP() return TweenPool.LOOP end	-- Loop from start to end, reseting each time

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
	if not start then return false, TweenPool.ERROR_BAD_START end
	if not target then return false, TweenPool.ERROR_BAD_TARGET end
	if not length then return false, TweenPool.ERROR_BAD_LENGTH end
	if not ease then return false, TweenPool.ERROR_BAD_EASING end
	if not update then return false, TweenPool.ERROR_BAD_UPDATER end

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

function TweenPool:remove( twn, updatemode )
	if twn then
		table.insert( self._toremove, twn )
		if updatemode then
			twn:callback( twn.args and unpack( twn.args ))
			if updatemode == tween.STOP then
				twn:update( twn.target )
			elseif updatemode == tween.RESET then
				twn:update( twn.start )
			end
		end
		return true
	else
		return false, TweenPool.ERROR_NIL_TWEEN
	end
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

function TweenPool:update( clock )
	self:flush()
	
	self._clock = clock

	local tweens = self._tweens
	for i = 1, #tweens do
		local twn = tweens[i] 
		local startclock = twn.startclock
		local t, b, c, d = clock - startclock, twn.start, twn.target - twn.start, twn.length
		
		if t >= d then
			twn:update( twn.target )

			local mode
			if twn.callback then
				mode = twn:callback( twn.args and unpack( twn.args ))
			end

			if mode == tween.PONG then
				twn.clock = clock
				twn.target, twn.start = twn.start, twn.target

			elseif mode == tween.LOOP then
				twn.startclock = clock

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

return setmetatable( TweenPool, { __call = function(_,...)
	return TweenPool.new( ... )
end })
