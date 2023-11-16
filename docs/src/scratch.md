# Scratchspace


## Youtube Player

```@raw html
<script src="https://www.youtube.com/iframe_api"></script>
<div id="youtube-player" style="width:640px;height:360px"></div>
<script>
    var player;
    function onYouTubeIframeAPIReady() {
        player = new YT.Player('youtube-player', {
            videoId: 'osM1R1PnR2U',
            playerVars: {
                'rel': 0,   // disable related videos
                'hd': 1,    // request HD
                'modestbranding': 1, // hide the YouTube logo
            },
        });
    }
</script>
```

## Garbage Collection

The garbage collector will affect the performance of this system.
Try to minimize heap allocations in your tasks.


To temporarily disable it, first open your OS resource monitor or task manager to show memory usage. Keep an eye on it - if it reaches 100%, julia *will* crash. Depending on your code and hardware, this can happen in seconds or in days. Then run:
```julia
GC.enable(false)
```
Once a performance-critical test is complete, I highly recommend re-enabling the garbage collector:
```julia
GC.enable(true)
```
This will be increasingly less of an issue as julia's garbage collector evolves for a multi-threaded world.


## Overview

useful for robotics, hardware interaction, and controls.
facilitates quickly writing high-performance glue code between custom hardware stacks and software.
which is not crippled by the Python interpreter.

unreliable processing and communication also prevents deadlocks from occuring

## Intro stuff

Code modularity.
Code modularization makes a lot of sense in robotics.
mainly for simplifying development and system management and increased robustness
In a system like ROS, the various modules of the software stack run as separate processes, are scheduled by the OS, and pass data between each other using pipes, the network stack, or other OS-level services.

In contrast, the various modules of software
run as coroutines within a multithreaded julia process
are scheduled by the julia task queue
and exchange information directly through a shared memory pool.

This allows for tremendous gains in performance - bypassing the OS entirely - at the cost of robustness.

For example, if a task segfaults, the entire julia process will segfault.

I would like to extend the topic system to allow for UDP-based interprocess communication, similar to LCM.

I would also want to preserve the JIT-based magic of julia, which allows for new code to be compiled and run at runtime. Perhaps Distributed.jl allows this?

This would pass the option/choice between robustness and performance to the user, and could be mixed and matched to suit the application at hand.




## What are the core ideas?

This may be the first robotics framework built on a JIT.
This allows the robot's code to be dynamically changed and rewritten at runtime.

That sounds like a nightmare from a reliability perspective.

Managing a script of constructor functions is really not so different than managing a launch file.

But, the benefits it brings are tremendous. Especially in the context of bringing up new hardware. ReactiveToolkit massively amplifies what a single developer can achieve in a short amount of time.

There are also the considerations of first compile time.
