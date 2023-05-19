# ReactiveToolkit.jl

Think of it as an asyncrhonous, reactive, realtime Simulink.
Simulink, but for scalable, open-source, high-performance hardware I/O.

This package provides tools to govern when code runs. What the code does is up to you.

## Overview
Code is organized into tasks and topics. Tasks do stuff, topics allow data to be shared between them.

## Topics: @topic

allowing values of type T to be safely and efficiently shared between parts of the system running on multiple threads.


```julia
@topic x = 10
@topic x::Int = 10
```
`@topic` is a macro ultimately creates an object of type `Topic{T}`.

A topic is a threadsafe container holding values of type T. In the example above, `x` is a `Topic{Int}`.

Note that `x` represents the container itself. We need a bit of extra syntax to access the value inside, which looks like this:
```julia
x[] = 1 # set the value of x
sin(x[]) # use the value of x
```



T can be anything you can represent in julia: primitive types like UInt16, abstract types like Number, dicts or structs encoding custom message types, variable length arrays, images, simulation models, symbolic differential equations, or even julia source code. It can also be of type Any.

```julia
@topic x = Trajectory{}
```
```julia
@topic x::Int = 10.0 # x holds Int64s, with initial value of 10
@topic y::Number = 10.0 # y holds Numbers, initially the Float64 10.0
@topic z::Number = 10 # 
@topic a::Any = 10.0

a[] = plot(rand(10))
```

### Custom Message Types
```julia
struct RobotStatus
    battery_level::Float64
    is_ok::Bool
end

@topic status = RobotStatus(100, true)
```

For more flexible messages:
```julia
@topic status = Dict("battery_level"=>100, "is_ok"=>true)
```


<!-- todo: "exotic" example: maybe unicodeplots? images? -->

If we lean into the abstraction, we can do things like this:
```julia

@topic fig = Figure()

let i = 1
    @on fig "autosave" begin
        save("./data/figure_$i.png", fig[])
        i+=1
    end
end

@on data "autoplot" begin
    fig[] = lines(data[])
end

# now we can automatically plot and save data simply by storing it:
data[] = rand(10)

```


## Tasks

Think of tasks as zero-argument functions (or blocks of code) that can be interrupted and scheduled across CPU cores.

<!-- loop() function example? -->

## Reacting to Changes: @on

General syntax:
```julia
@on "name" topic loop() finalizer()
```
where name and finalizer are optional.

`name` should be a string and is optional
`topic` should be a Topic{T}
`loop()` should be an *expression* describing the loop task
`finalizer()` should be an expression descring the finalizer task, and is optional


```julia
@on x println(x[])
@on "name" topic loop() finalizer()
```





## Timing: @at

```julia
@topic led_cmd=false
toggle_led() = led_cmd[] = !led_cmd[]
@at Hz(10) toggle_led()
@on led_cmd write(mcu, "SET LED $led_cmd")
```


## Manual Mode: @loop
This construct exposes the mechanisms for scheduling to the user.
It is particularly useful for eternal interfaces.
`@loop` might be renamed to `@always`
In addition to topics, is the other 'base' primitive of this package. `@on` and `@at` are just wrappers for it.

Think of your code as going inside of a `while true` loop. You are responsible for throttling how fast it runs which resources it blocks.

<!-- TCPIP example? -->
<!-- Serial example -->

```julia
@loop "serial monitor" begin
    x[] = parse(UInt16, readline(port))
end begin # finalizer (optional)
    isopen(port) && close(port)
end
```
In the example above, the task waits on `readline(port)`.

Sometimes, we want to ensure a task runs on the 'main' thread. Especially for packages which are not multithreaded, like making plots with `GLMakie`.
```julia
@looplocal "realtime plot" begin
    wait(x)
    plot!(ax, x[])
end
```
The code above is functionally identical to:
```julia
@on x plot!(ax, x[])
```
except it will not jump between multiple threads.


## Reacting to Groups: On Any/On All

To run a task in response to a change in any element x1,x2,x3

```julia
@onany (x1,x2,x3) anytask()
@onall (x1,x2,x3) alltask()
```








## Note on Metaprogramming
Macros see inputs as *expressions* that is to say source code as source code.
There are many equivalent syntaxes:

```julia
@topic x::Number = 0
@topic y::Number = 0
function loop()
    y[] = sin(x[])
end
@on x loop()
@on x y[] = sin(x[])
```
















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