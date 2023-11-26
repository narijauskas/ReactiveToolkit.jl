# Manual
It may be worth familiarizing yourself with the concepts in the [Asyncrhonous Programming](https://docs.julialang.org/en/v1/manual/asynchronous-programming/)
chapter of the Julia manual before proceeding.


## @topic & Topics

Time-varying states are represented by the `Topic{T}` type. A topic is a thread-safe container holding values of type `T`. The name is borrowed from ROS; they fulfill a similar role to ROS topics, but work quite differently.

Topics are like (mostly) thread-safe Observables. They are essentially a 2-element circular buffer with mutual exclusion enforced on writes, but allowing unlimited concurrent reads, which reuse the most recently written value. They can be thought of as a Last-In, Only-Out (LIOO?) queue, or simply a thread-safe box containing a variable.

The idea is that the most recent value written to the topic is the most valid representation of that state, older values are obsolete, and discarded. It is generally advised to only have a single task be the "source" of the topic.

`T` can be any type available in Julia itself: primitive types like `UInt16`, abstract types like `Number`, or even `Any`, dicts or structs encoding custom message types, variable length arrays, images, simulation models, symbolic differential equations, or even julia source code.

They can be made using the `@topic` macro, which creates an automatically named topic with an inferred type, bound to the specified variable:
```julia
@topic x::Int = 10.0    # x holds Int64s, with initial value of 10
@topic y::Number = 10.0 # y holds Numbers, initially the Float64 10.0
@topic z::Number = 10   # z holds Numbers, initially the Int64 10
@topic a::Any = plot(rand(10)) # the world is your oyster
```

They can also be created manually, for example in loops or generators:
```julia
ys = [Topic(0; name="y$i") for i in 1:100]
zs = [Topic{Float64}(0; name="y$i") for i in 1:100]
```

The variable represents the topic itself. Their value can be accessed or set using `[]`:
```julia
@topic x = 0.0
@topic y = 0.0
x[] = 1 # set the value of x
1 == x[] # use the value of x
typeof(x) # Topic{Float64}
typeof(x[]) # Float64
y[] = sin(x[])
```

Note that things get tricky when the topic is a mutable type. **As a general rule, don't mutate the value of a topic** - replace it with a new value instead:
```julia
@topic x = [1,2,3]
x[] = [1,2,3,4] # this is fine
push!(x[], 5) # this is not
```

Once I find an elegant way to automate mutation, I will add it. For now, consider:
```julia
let _x = x[]
    push!(_x, 5)
    x[] = _x
end
```


## @on
The `@on` macro builds a task which will run in response to a topic update. For example:
```julia
@topic x = 0.0
@topic y = 0.0
@on x y[] = sin(x[])
```
Now, whenever `x` is updated, `y` will be updated to `sin(x)`.

It expects one of the general forms:
```julia
@on topic "name" loop_ex
@on topic "name" init_ex loop_ex final_ex
```
 * `topic` is the topic to react to
 * `name` is an optional string
 * `init_ex` is an expression to run once on task creation
 * `loop_ex` is the expression to run on each update to the topic
 * `final_ex` is an expression to run once on task destruction


## Representing Time

ReactiveToolkit uses the `Nano` type for its internal representation of time, which corresponds to the system clock in nanoseconds as a `UInt64`. This design choice was made to differentiate ReactiveToolkit's representation of time from the various notions of time provided by other packages, and maintain compatibility between them by requiring explicit conversions to `Nano`s.

`Nano`s can be created using the constructors `nanos`, `micros`, `millis`, or `seconds`, and their operation should be self-explanatory. For convenience, the `Hz`, `kHz`, and `MHz` constructors are also provided, which return the period of the specified frequency in `Nano`s.

ReactiveToolkit also natively supports conversion from `Dates.AbstractTime` subtypes, such as `Second`, `Minute`, `Hour`, `Day`, etc. These can be used in place of the `Nano` constructors above.

```julia
# the following are equivalent:
@after Hz(1/60)     do_the_thing()
@after seconds(60)  do_the_thing()
@after Second(60)   do_the_thing()
@after Minute(1)    do_the_thing()
```

In fact, it is possible to use any notion of time from any source by defining an appropriate constructor method for `Nano`:
```julia
struct MartianDay
    val::Number
end

Nano(d::MartianDay) = Nano(8.86426641e13*d.val)

@every MartianDay(1) println("and so, another day goes by on Mars")
```

`ReactiveToolkit.now()` returns the current timestamp in `Nano`s.

`ReactiveToolkit.autosleep(t::Nanos)` will cycle through various sleep strategies to minimize CPU usage while still maintaining the specified period far more accurately than the OS scheduler would otherwise allow.


## @after

The `@after` macro builds a task which will run once on any available thread after a delay. For example:
```julia
@after seconds(1) println("hello from thread $(Threads.threadid())")
```

It expects the general form:
```julia
@after delay "name" task_ex
```
 * `delay` is the duration of the delay
 * `name` is an optional string
 * `task_ex` is the expression to delay the execution of

A useful design pattern is to use `@after` to control task lifetime:
```julia
@after seconds(1) begin
    i = 0
    task = @every millis(10) println("hello! i is $(i+=1)")
    @after seconds(3) kill(task)
end
```

## @every

The `@every` macro builds a task which will run repeatedly on any available thread at a specified interval. For example:
```julia
@every seconds(10) println("... is this annoying yet?")
@every Minute(15) println("remember to take a break!")

# generate a 1Hz sine wave, updated at 100Hz:
@topic x = 0.0
@every millis(10) x[] = sin(2π*now()*1e-9)
```

It expects one of the general forms:
```julia
@every interval "name" loop_ex
@every interval "name" init_ex loop_ex final_ex
```
 * `interval` is the duration of the delay between runs
 * `name` is a string (and is optional)
 * `init_ex` is an expression to run once on task creation
 * `loop_ex` is the expression to run on each interval
 * `final_ex` is an expression to run once on task destruction


## @loop
The `@loop` macro builds a task which will run in response to an arbitrary event.
This is the low-level primitive on which `@on` and `@every` are built.
It is useful for interacting with hardware, or other external processes.
**Importantly: The user is responsible for ensuring that the loop task expression includes one blocking call to work properly.**
For example, here is an Arduino-style serial monitor which can be defined directly in the REPL:
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
# do stuff
kill(tk)
```
This example shows the expanded syntax for including an optional initializer and finalizer in addition to the main loop expression. As mentioned above, loop task expression **must** inlcude a blocking call to work properly. In the example above, the task waits on `readline(port)` - thus, it will run whenever a new packet arrives. For contrast, here is a more manual implementation:

```julia
using ReactiveToolkit, LibSerialPort

port = SerialPort("/dev/ttyACM0")
open(port)
tk = @loop "serial monitor" println(readline(port))

kill(tk)
close(port)
```
It is often useful to start with the manual version and build up to re-usable constructors as needed. Note that many older microcontrollers (which use a UART-based FTDI chip to implement USB communication) will also need a baud rate set as the second argument to the SerialPort constructor.
