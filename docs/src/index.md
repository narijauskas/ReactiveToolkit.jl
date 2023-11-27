# ReactiveToolkit.jl

## What is it?

Hello! This package provides some tools to enable asynchronous, concurrent, reactive, "soft real-time" programming in Julia. The target audience of this package consists of roboticists working at the intersection of controls theory and experimental hardware. It should prove useful for single developers or small teams who are not willing or able to implement a full real-time stack just to test their control implementation on benchtop hardware.

ReactiveToolkit.jl provides the type `Topic{T}` to represent a time-varying state of type `T` that can be shared between concurrently running tasks, and several macros (`@on`, `@every`, `@after`, and `@loop`) to transform arbitrary code into a network of concurrent tasks, augmented with some added control flow and error handling machinery which will run in reaction to topic updates, time, or arbitrary events.

It also provides some timing functions which efficiently circumvent the limitations of the OS scheduler and help achieve precise, high-frequency task execution. Finally, it provides some utilities for monitoring and managing the execution of tasks (possibly thousands of them).

Compared to robotics frameworks like ROS, LCM, or YARP, ReactiveToolkit.jl sacrifices some robustness and safety for tremendous gains in flexibility, ease of use, and often performance. Using an unfair metric, ReactiveToolkit.jl is some 10,000x faster than ROS. (I said unfair - more details coming soon).

!!! warning "ReactiveToolkit.jl is not suitable for mission- or safety-critical applications."
    In other words, don't use this for your missile. But it may prove useful for your PhD.\
    Please read the "What's the catch?" section at the bottom of this page before using this package.


## What can it do?

For a demo, please see the shameless plug of my research below. The hardware in this video is the result of our group's research on the development of intelligent soft robotic materials with integrated sensing, actuation, and control.
The high-level software for this system was written almost entirely in an early development version of ReactiveToolkit.jl, which was responsible for both real-time closed loop control (200-600Hz), and data logging at 1kHz. Depending on the mode of operation, this meant simultaneously tracking over 1000 independent states. 

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
#=
There's certainly a lot I'm not showing here,
as I'm assuming the "main" system stack is already running.
This means we already have a bunch of topics defined,
and have started low-level tasks (eg. hardware drivers, controllers, filters, etc.)
=#

@topic kt = 30.0 # rate tuning parameter
@topic kxy = 1.0 # spatial tuning parameter

radial_ripple = @every Hz(200) "reference" begin
    M = 8000 # magnitude (volts)
    xs = LinRange(-10, 10, 10)
    ys = LinRange(-10, 10, 10)
    t = now()*1e-9 # current time in seconds
    VREF[] = [M*(sin(kxy[]*sqrt(x^2 + y^2) - kt[]*t)+1)/2 for x in xs, y in ys]
end

# to adjust the shape of the ripple, eg:
kt[] = 60
kxy[] = 2

# once we're done filming the demo,
kill(ripple)
```
This code can be entered directly in the REPL, compiled, and executed while the hardware continues to run. No need to restart hardware, or recompile the full stack!

## How is it used?
Please consult the [Manual](@ref) for a more detailed description of the API.


## What's the catch?
Given what ReactiveToolkit.jl is, it is important to understand it's limitations. In no particular order:

#### 1. Soft Real-Time is NOT Real-Time
ReactiveToolkit enables "soft real-time" programming in julia. **Soft real-time is *NOT* real-time.**
Real-time systems make guarantees about the timing of their operations.
Soft real-time is the idea that if code runs fast enough, the result is practically the same. Consequently ReactiveToolkit will work well until it can't keep up. While it's actually pretty good at this, it is important to understand that it makes **none** of the guarantees typically expected of real-time systems. Everything still runs on top of a shared-time OS, and is subject to its whims (at least on Linux there may be ways to circumvent this).

#### 2. Unreliable Communication
ReactiveToolkit is built on top of an unreliable, UDP-like communication system. The objective is for the most recent information to always be available to whichever task desires it, but will drop information if it can't keep up instead of deadlocking. This is by design. Tasks should be designed with this assumption in mind.

#### 3. GC and JIT
The reality of Julia is that it has two features which are almost never found in real-time systems: garbage collection and just-in-time compilation. These will both cause your code to freeze unexpectedly, and for unpredictable amounts of time. ReactiveToolkit does nothing to avoid the GC and JIT. This is important to be aware of. It is up to the user to ensure that their code is not triggering garbage collection or compiling functions during critical sections. 

The time-to-first-plot problem has not gone away: if your code encounters a new branch, it will take time to compile. This could cause problems, eg. if your drone encounters an obstacle and needs to spend valuable time compiling the obstacle avoidance code.

As of 1.9, julia's garbage collector is not concurrent, and will pause all tasks while it runs. When this occurs is entirely unpredictable, and will take an unbounded amount of time to run. Workarounds are to write code that minimize allocations (avoiding them entirely is all but impossible in multi-threaded code) or to pause the GC during critical sections.
```julia
GC.enable(false)
# https://downloadmoreram.com/
GC.enable(true)
```
Keep an eye on RAM usage in your OS resource monitor - if it reaches 100%, julia *will* crash. Depending on your code and hardware, this can happen in seconds or in days. A *much* better solution will come in the form of a task-local/concurrent garbage collector which to my understanding is actively being developed as julia evolves for a multi-threaded world.


#### 4. Multi-Threaded, Not Multi-Process
It is a common pradigm in robotics to modularize the system into multiple processes with independent memory, which provides robustness against crashes in any part of the system. ReactiveToolkit does not do this (yet), instead, everything runs within one instance of julia and uses a shared memory pool. If you segfault one task, you segfault your entire system. Corollary: you will likely find a way to segfault something.

#### 5. This is v0.1.0
This API is still experimental. Please expect it to change.
That said, I'd love to hear your feedback on what works and what doesn't, and what you'd like to see in the future!


## References

ReactiveToolkit.jl draws inspiration from
[Observables.jl](https://github.com/JuliaGizmos/Observables.jl),
the internals of [Makie.jl](https://docs.makie.org/stable/),
robotics frameworks such as
[LCM](http://lcm-proj.github.io/lcm/),
[YARP](https://www.yarp.it/),
[ROS](https://www.ros.org/),
block diagram representations of signals and transfer functions from control theory (think [Simulink](https://www.mathworks.com/products/simulink.html)),
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
the [composable task-based concurrency](https://julialang.org/blog/2019/07/multithreading/) system of Julia itself,
and a splash of practical experience.