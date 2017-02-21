![Build Status](https://travis-ci.org/iskolbin/tween.svg?branch=master)
[![license](https://img.shields.io/badge/license-public%20domain-blue.svg)]()

Tween
=====

Lua tweening library. Provides `TweenPool` class to manage tweening animations.

TweenPool.new( clock = 0 )
--------------------------

Creates new tween pool with `clock` time.

TweenPool:anim( start, target, length, ease, update[, callback, ... ])
----------------------------------------------------------------------

TweenPool:remove( tween, updatemode = STOP )
--------------------------------------------

TweenPool:contains( tween )
---------------------------

TweenPool:flush()
-----------------

TweenPool:update( clock )
-------------------------

TweenPool:reset( clock )
------------------------
