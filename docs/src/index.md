# ReactiveToolkit.jl

## Overview

This is a simple framework for writing soft realtime code based on julia's system of task-based concurrency.

It has 2 functional components:

**Actions** are repeating tasks of the form:

```julia
on_start()
axn = @repeat "name" on_loop() on_stop()
```

**Signals** are time-varying values that can be shared between them.
```julia
x = Signal(1) # Create a Signal{Int}
x[] = 2 # set value (and notify)
x[] # get value
```


## Example

To print the value of x on each update:
```julia
x = Signal(0)
@on x println(x[])
```


## Example

```julia
x = Signal(0.0)
y = Signal(0.0)
@on x begin
    y[] = sin(x[])
end
```

Now, whenever the value of `x` is changed, `y` will be set to `sin(x)` after a slight delay.
```julia
x[] = 1.0
yield()
y[] # returns sin(1.0) after a slight delay
```

## Other

```julia

axn = @repeat "say hello" begin
    println("hello")
    sleep(1)
end
```

```julia
@on x :(ex)

@repeat "on x" begin
    wait(x)
    :(ex)
end
```

**Signals** are time varying values that can be shared across tasks - the states of the robot



### Soft Realtime
An RTOS strictly bounds the time a task can run.
Regular OS distributes processing resources to tasks as they become available.

Soft realtime is the best we can do without an RTOS.
Hard realtime is true (guaranteed) realtime.


## Signals

In order to communicate between

```julia
x = Signal(1) # Create a Signal{Int}
x[] = 2 # set value (and notify)
x[] # return value
```

Thread safe.


```julia
wait(x)
notify(x)
```

## Actions

Think of tasks as zero-argument functions (or blocks of code) that can be interrupted and scheduled across CPU cores.

An action is a set of 3 'tasks':

```julia
on_start()
axn = @repeat "name" on_loop() on_stop()
```

| main thread | axn thread |
| --- | --- |
| `setup_ex` |  |
| `axn = ...` | `main_ex` |
| | `main_ex` |
| | `main_ex` |
| `stop!(axn)` | `main_ex` |
| | `final_ex` |

All: `while(isactive(axn))`

Base primitive:

```julia
axn = @repeat "name" begin
    # custom wait, eg. recv(socket)
    # ...
end
```

These generate a `wait()` condition:

```julia
axn = @on(xs...) do
    #...
end

@on x println("hello")
@on y fxn(a, b, c)
```

```julia
@on all(xs...) begin
    # ...
end

@on any(xs...) begin
    # ...
end
```

```julia
axn = @every(hz) do
    #...
end

@at Hz(1) println("hello")
@at Hz(1) "printer" begin
    println("hello")
end

```


### Stopping Actions
```julia
stop!(axn)
```

If needed, can do
```julia
notify(x, 0; error=true)
```

### One-Shot Reactions
For now:
```julia
x = Signal(0)
@spawn begin
    wait(x)
    println(x)
end
```
Maybe make a `@once` macro or function?

### Global Overview
Like a task manager of sorts.

`ReactionList` type.

```julia
RTk.list # list of running tasks along with index #
    # [1] map z on x,y - [active]
    # [2] Reaction every 10Hz - [done]
    # [3] NatNetClient - [failed]
```

```julia
stop!(RTk.index[i]) # to stop task at index i
stop!(RTk.index["name"]) # to stop all w./ matching name
stop!(RTk.index...) # to stop all
```

```julia
RTk.clean!() # to clean all done/failed
```


Plotting:
```julia
RTk.graph!(ax; kw...) # graph into any Makie backend, subfigure, etc.
```

### Internals
```julia
notify()
wait()
name!(axn, name::String)
isactive(axn)
RTk.daemon() # handles timing
```

## Operators

* map/map!
* foldp


## Future
Check out [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl)