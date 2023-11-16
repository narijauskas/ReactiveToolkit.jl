# ReactiveToolkit.jl

If we want to set up a publisher to run periodically, and a subscriber to react to its output, why not just... tell the code to do that?

**ReactiveToolkit.jl is not suitable for mission- or safety-critical applications.**

## What is this package?

This package enables asynchronous, reactive, "soft real-time" programming in julia.
The target audience of this package is roboticists working at the intersection of controls theory and experimental hardware.

It is meant for single developers or small teams who are not willing or able to implement a full real-time stack just to test their novel control laws on benchtop hardware.


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


