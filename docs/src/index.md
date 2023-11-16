# ReactiveToolkit.jl

## What is it?

Hello! This package provides some tools to enable asynchronous, concurrent, reactive, "soft real-time" programming in Julia.

The target audience of this package consists of
roboticists working at the intersection of controls theory and experimental hardware.
It is meant for single developers
or small teams
who are not willing or able to implement a full real-time stack just to test their novel control laws on benchtop hardware.

To do so,
It sacrifices robustness and safety for flexibility and ease of use.
Some of the most significant disclaimers are discussed in a section below.

For a more detailed discussion of the limitations of this package, please see [here](@ref Disclaimers).


That being said,

!!! warning "ReactiveToolkit.jl is not suitable for mission- or safety-critical applications."
    In other words, don't use this for your missile. But it may prove useful for your PhD.

extend the task-based concurrency system of julia to facilitate
writing in a reactive paradigm

**reactive programing**

is a way of creating event-driven programs in terms of time-varing data streams.



It should be useful for robotics, hardware interaction, and controls.

It is built on julia's metaprogramming and task-based concurrency features.

It provides one type to share information, and several macros to transform arbitrary code into a network of asynchronous, reactive tasks.

It adds one type to represent data streams of arbitrary types.
`Topic{T}` represents a time-varying state of type `T`.

## References

ReactiveToolkit.jl draws inspiration from
[Observables.jl](https://github.com/JuliaGizmos/Observables.jl),
the internals of [Makie.jl](https://docs.makie.org/stable/),
task management and data marshalling frameworks for robotics such as
[LCM](http://lcm-proj.github.io/lcm/) and
[ROS](https://www.ros.org/),
block diagram representations of signals and transfer functions from control theory,
notions of functional reactive programming
[[1]](http://people.seas.harvard.edu/~chong/abstracts/CzaplickiC13.html)
[[2]](https://elm-lang.org/assets/papers/concurrent-frp.pdf)
including the design of the
[Elm](https://elm-lang.org/) programming language,
and other julia packages for reactive programming such as
[Reactive.jl](https://github.com/JuliaGizmos/Reactive.jl),
[ReactiveBasics.jl](https://github.com/tshort/ReactiveBasics.jl),
[Rocket.jl](https://github.com/biaslab/Rocket.jl), and
[Signals.jl](https://github.com/TsurHerman/Signals.jl),
as well as the task-based concurrency system of Julia itself.



## Topics

## Reactive Tasks
Reactive tasks can be created with one of several macros, namely `@on` and `@every`, provided by ReactiveToolkit.

These macros transform arbitrary source code into an asynchronous task with some added control flow and error handling machinery which will run in reaction to topic updates, time, or arbitrary events. These macros create `ReactiveTask` types, which holds some control flow variables along with the created `Task`.


## How is it used?

Time-varying states are represented by the `Topic{T}` type. A topic is a thread-safe container holding values of type `T`. In the example above, `x` is a `Topic{Int}`. Their value can be accessed or updated using `[]`.


Topics are implemented essentially as a circular buffer
holding values of type `T`
with mutual exclusion enforced on writes which
allows unlimited concurrent reads of the most recently-written value.
This most recent value is considered to be the most valid representation of that state.



```julia
# making topics
@topic x = 0
@topic y::Number = 0

# using topics
y[] = sin(x[])
```
<!-- in control flow, error handling, and threading code -->
Reactive tasks can be created with one of several macros, namely `@on` and `@every`, provided by ReactiveToolkit.

@macro [trigger] "name" init_ex loop_ex final_ex

These macros transform arbitrary source code into an asynchronous task with some added control flow and error handling machinery which will run in reaction to topic updates, time, or arbitrary events.

```julia
# react to topics
@on x y[] = sin(x[])

# react to time
tk = @every millis(50) begin
    x[] = sin(2π*now()*1e-9)
end

# one-shot version of @every
@after seconds(3) kill(tk)
```

The `@loop` macro generalizes `@on` and `@every` to arbitrary events. It is useful for interacting with hardware, or other external processes. For example, here is an Arduino-style serial monitor which can be defined directly in the REPL:

```julia
using ReactiveToolkit, LibSerialPort

function SerialMonitor(addr)
    # objects can be captured by the task
    # but kept out of global scope
    port = SerialPort(addr)

    @loop "$addr serial monitor" begin
        # initializer
        !isopen(port) && open(port)
    end begin
        # loop task
        println(readline(port))
    end begin
        # finalizer
        isopen(port) && close(port)
    end
end

tk = SerialMonitor("/dev/ttyACM0")
kill(tk)
# etc.
```
This example shows the expanded syntax for including an optional initializer and finalizer in addition to the main loop expression. The loop task expression must inlcude a blocking call to work properly. In the example above, the task waits on `readline(port)` - thus, it will run whenever a new packet arrives. For contrast, here is a more manual implementation:

```julia
using ReactiveToolkit, LibSerialPort

port = SerialPort("/dev/ttyACM0")
open(port)
tk = @loop "serial monitor" println(readline(port))

kill(tk)
close(port)
```
It is often useful to start with the manual version and build up to re-usable constructors as needed. Note that most older microcontrollers (which use a UART-based FTDI chip to implement USB communication) will also need a baud rate set as the second argument to the SerialPort constructor.

## What can it do?

For a demo, please see the shameless plug of my research below. The hardware in this video is the result of our group's research on the development of intelligent soft robotic materials with integrated sensing, actuation, and control.
The high-level software for this system was written almost entirely in an early development version of ReactiveToolkit, which was responsible for both real-time closed loop control (200-600Hz), and data logging at 1kHz. Depending on the mode of operation, this meant simultaneously tracking over 1000 independent states. 

```@raw html
<iframe style="width:640px;height:360px" src="https://www.youtube.com/embed/osM1R1PnR2U?rel=0" title="Shape-shifting display for 3D designs" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
```

Running on a modern, but modest PC (Ryzen 7 5800X, 32GB RAM), the software stack handled:
 * management of bidirectional data streams to 20 microcontrollers at 1kHz each
 * processing 3D point clouds streamed from a motion capture videography system at 240Hz
 * real-time 3D surface fitting and plotting on a 60Hz monitor using GLMakie.jl
 * recording, storage, and processing of ~1 million data points per second at full send

From a UX/DX perspective, the ability to download dependencies; write, compile, and execute additional robot code at runtime; all with the full OS-agnostic expressiveness and ecosystem of julia at your fingerprints, is... pretty nice, to say the least. Using ReactiveToolkit, many of the demos shown in the video could be written in under a few hours. For example, to generate the radial ripple shown at 0:08:
```julia
ripple = @every Hz(200) begin
    VREF[] = [sin(t) for x in 1:10, y in 1:10]
end

# whenever we're done
kill(ripple)
```
This code can be entered directly in the REPL, compiled, and executed while the hardware continues to run. No need to restart hardware, or recompile the full stack!

## What's the catch?
## Limitations

The target audience of this package is
roboticists working at the intersection of controls theory and experimental hardware.

It is meant for single developers
or small teams
who are not willing or able to implement a full real-time stack just to test their novel control laws on benchtop hardware.

To do so,
It sacrifices robustness and safety for flexibility and ease of use.
Some of the most significant disclaimers are discussed in a section below.
That being said,

!!! warning "ReactiveToolkit.jl is not suitable for mission- or safety-critical applications."
    In other words, don't use this for your missile. But it may prove useful for your PhD.

ReactiveToolkit is based on unreliable communication.

ReactiveToolkit enables "soft real-time" programming in julia. **Soft real-time is *NOT* real-time.**
Real-time systems make guarantees about the timing of their operations.
Soft real-time is the idea that if code runs fast enough, the result is practically the same. Consequently ReactiveToolkit will work well until it can't keep up, and makes **none** of the guarantees typically expected of real-time systems. Everything still runs on top of a shared-time OS.
## Disclaimers