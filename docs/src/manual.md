# Manual
It is worth taking a look at the [Asyncrhonous Programming](https://docs.julialang.org/en/v1/manual/asynchronous-programming/)
chapter in the Julia manual.

## Representation of Time

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
@every Hz(60) println("hello from thread $(Threads.threadid())")

tks = map(1:10) do i
    @every Hz(60) ReactiveToolkit.busywait(millis(10))
end
kill.(tks)
```