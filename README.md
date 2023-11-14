# ReactiveToolkit.jl

If we want to set up a publisher to run periodically, and a subscriber to react to its output, why not just... tell the code to do that?

## What is this package?
- provides tools to facilite reactive, soft real-time programming in julia

useful for robotics, hardware interaction, and controls.

facilitates quickly writing high-performance glue code between custom hardware stacks and software.
which is not crippled by the Python interpreter.

## Quickstart
Install julia, and add this package. It's recommended to start julia with mulitiple threads: `julia -t auto`.

How to make topics?
How to change topic value?
How to react to topics?
How to react to time?
How to react to anything?

## Disclaimers
The API is still experimental. Please expect it to change.

Communication is unreliable. This is by design. Tasks should be designed with this assumption in mind.
The assumption is that the most recent value of a topic is the most valid.
<!-- There is no guarantee that the value of a topic will propogate to all tasks which depend on it. -->
<!-- Topics as continuous signals. -->

<!-- Tasks will be skipped and topic values may not propogate -->
It prevents deadlocks

Time will drift. This is not a real-time system. It is a soft real-time system.
This will work while you have the resources to fullfill what you ask of it. It's performance will slowly degrade past that point.

Do not let your computer enter sleep mode while this is running and expect it to continue working normally.

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

**In other words, don't use this for your missile. But, it might prove very useful for your PhD.**

<!-- What is a task? -->
and, how does asyncrhonous programming work in julia?

<!--  What is metaprogramming? -->


## @topic - Sharing Data Between Tasks
sharing data between tasks
implemented as a 2 element circular buffer with mutual exclusion enforced on writes, but allowing unlimited concurrent reads, which don't pop the value from the buffer.

This can be thought of as a Last-In, Only-Out queue.

Topics can be any type supported by Julia, including primitives, abstracts, custom structs, and variable-length arrays.

The `@topic` macro automates this process. It creates a topic bound to a variable with the name of the variable.

```julia
@topic name::T = value
@topic name = value
```

Topics must always have a value.



## @every - Timed Repetition
<!-- `@at` was also considered, but makes less sense beyond Hz -->

```julia
@every seconds(1) println("...is this annoying yet?")
```




will accept ReactiveToolkit.jl timing types (`Nano`s)
`nanos`
`micros`
`millis`
`seconds`

one of the constructor functions for `Nano`, ReactiveToolkit's internal timing type. These constructors are `nanos`, `micros`, `millis`, and `seconds`, and their use should be self-explanatory.

The name `Nano` was chosen to differentiate our idea of nanoseconds from any other packages which provide notions of time, and maintain compatability between them.

ReactiveToolkit natively supports `Dates.AbstractTime` subtypes, such as `Second`, `Minute`, `Hour`, `Day`, etc.

```julia
@every Minute(10) println("remember to take occasional breaks")
```

The snippet below was taken after the code had been running for a few hours. Note that the time is not exactly 10 minutes apart, but within several milliseconds. This is close enough for most purposes.
```
the time is now 2023-11-13T11:58:10.843, remember to take a break!
the time is now 2023-11-13T11:59:10.842, remember to take a break!
the time is now 2023-11-13T12:00:10.831, remember to take a break!
the time is now 2023-11-13T12:01:10.845, remember to take a break!
the time is now 2023-11-13T12:02:10.834, remember to take a break!
the time is now 2023-11-13T12:03:10.830, remember to take a break!
the time is now 2023-11-13T12:04:10.839, remember to take a break!
the time is now 2023-11-13T12:05:10.840, remember to take a break!
the time is now 2023-11-13T12:06:10.838, remember to take a break!
the time is now 2023-11-13T12:07:10.833, remember to take a break!
the time is now 2023-11-13T12:08:10.836, remember to take a break!
the time is now 2023-11-13T12:09:10.833, remember to take a break!
the time is now 2023-11-13T12:10:10.839, remember to take a break!
the time is now 2023-11-13T12:11:10.839, remember to take a break!
the time is now 2023-11-13T12:12:10.841, remember to take a break!
the time is now 2023-11-13T12:13:10.843, remember to take a break!
the time is now 2023-11-13T12:14:10.840, remember to take a break!
the time is now 2023-11-13T12:15:10.839, remember to take a break!
the time is now 2023-11-13T12:16:10.838, remember to take a break!
the time is now 2023-11-13T12:17:10.844, remember to take a break!
the time is now 2023-11-13T12:18:10.832, remember to take a break!
the time is now 2023-11-13T12:19:10.836, remember to take a break!
the time is now 2023-11-13T12:20:10.841, remember to take a break!
the time is now 2023-11-13T12:21:10.836, remember to take a break!
the time is now 2023-11-13T12:22:10.846, remember to take a break!
the time is now 2023-11-13T12:23:10.839, remember to take a break!
the time is now 2023-11-13T12:24:10.841, remember to take a break!
the time is now 2023-11-13T12:25:10.845, remember to take a break!
```

Code that doesn't use print statements and smaller intervals will be more accurate, often down to the tens of microseconds.


In fact, it is possible to use any notion of time as long as the appropriate constructor for `Nano` is defined:
```julia
struct Hz
    hz::Float64
end

ReactiveToolkit.Nano(x::Hz) = Nano(1e9/Hz.hz)

@every Hz(3) println("this will run 3 times per second")
```




To blink an LED on a microcontroller 10 times a second could be done as follows:

```julia
using ReactiveToolkit
using LibSerialPort

@topic led_cmd = false
mcu = SerialPort("COM3")

@every millis(100) "led blinker" begin
    !isopen(mcu) && open(mcu)
end begin
    led_cmd[] = !led_cmd[]
    write(mcu, "set led $(led_cmd[])\r\n")
end begin
    isopen(mcu) && close(mcu)
end
```
Note that this example assumes a microcontroller with non-UART based native USB (like a Teensy 4.x or ESP32-S3) on port `COM3` with firmware set up to react to the serial commands `set led false` and `set led true`.


Also note that serial transfers have a non-negligible latency, so this design pattern is not a good idea above 200Hz.



## Reactivity (@on)
reacting to tasks
The `@on` macro creates tasks which react to updates to a topic.

General syntax:
```julia
@on topic loop_ex
@on topic "name" loop_ex
@on topic "name" init_ex loop_ex final_ex
@on topic init_ex loop_ex final_ex
```
where name and finalizer are optional.

The `topic` and `loop_ex` are required.
A `name` is optional, will be autogenerated otherwise.
A `init_ex` and `final_ex` are optional, but if one is provided, both must be provided.

`name` should be a string and is optional
`topic` should be a Topic{T}
`loop()` should be an *expression* describing the loop task
`finalizer()` should be an expression descring the finalizer task, and is optional

The task will update whenever the value of the topic is updated by another task using `topic[] = value`

```julia
@on x println(x[])
@on "name" topic loop() finalizer()
```



## Extendability @loop
custom tasks
along with topics this is the basic building block of the package
`@on` and `@every` are implemented using `@loop`

## Stopping Tasks
Tasks are stopped using `kill(task)`:
```julia
tk = @every seconds(0.5) println("...is this annoying yet?")
# wait for it to get annoying
kill(tk)
```

If we forget to bind the task to a variable name (this happens often), it can be found and killed using `rtk_tasks()`.

Note that kill only *requests* that the task stop. The task will continue to wait on its blocking call. If the task is waiting on an external event, it will continue to show as `active` until that event occurs. I intend to rework the task killing mechanisms to be more robust, transparent, and extensible in the future.


## Utilities
rtk_tasks()
rtk_topics() <- maybe
rtk_kill_all()
rtk_clean()


Consider the task which monitors x and prints its value whenever it changes:
```julia
@on x "x monitor" println("x is now: $(x[])")
```

A useful design pattern is to wrap a commonly used task template in a constructor function.
We can then use and reuse this constructor to generate tasks with behavior that can be customized to a given context via its arguments. For example, this is exactly how we imlement `ReactiveToolkit.echo`:

```julia
echo(x::AbstractTopic) = @on x "echo $(x.name)" println(x.name, ": ", x[])
```

```julia
@topic x = 0
echo_x = echo(x)
# while active, the echo_x task will print the value of x whenever it changes
kill(echo_x)
```

