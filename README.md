[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://stand-with-ukraine.pp.ua)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://narijauskas.github.io/ReactiveToolkit.jl/dev)
# ReactiveToolkit.jl

Hello! This package provides some tools to enable asynchronous, concurrent, reactive, "soft real-time" programming in Julia. The target audience of this package consists of roboticists working at the intersection of controls theory and experimental hardware. It should prove useful for single developers or small teams who are not willing or able to implement a full real-time stack just to test their control implementation on benchtop hardware.

**ReactiveToolkit.jl is not suitable for mission- or safety-critical applications.**

For more information, please see the [documentation](https://narijauskas.github.io/ReactiveToolkit.jl/dev)!

## Crash Course

Topics represent the time-varying states of the system, and can safely share data between tasks. Their current value is used or updated using `[]`.
```julia
# making topics
@topic x = 0
@topic y::Number = 0

# using topics
y[] = sin(x[])
```

ReactiveToolkit also provides several macros to transform arbitrary code into asynchronous tasks which can react to topic updates, time, or arbitrary events.
```julia
# react to topics
tk1 = @on x y[] = sin(x[])
tk2 = @on y "y monitor" println("y is now: ", y[])

# react to time
tk3 = @every Hz(10) println("...is this annoying yet?")
tk4 = @after seconds(3) kill(tk1)

# support for initializers/finalizers
tk5 = @every Hz(10) begin
    println("task initialized - hello!")
end begin
    println("...is this annoying yet?")
end begin
    println("finalizing a task - goodbye!")
end

# react to events
tk6 = @loop "serial monitor" println(readline(port))

# stacktraces for debugging
tk7 = @on x throws_error()
# why did my task fail?
debug(tk7)

# these might come in handy :)
kill(ans)
kill(last(rtk_tasks()))
rtk_kill_all()
```
