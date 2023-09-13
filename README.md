# ReactiveToolkit.jl
A set of primitives which bring "soft real-time" functionality to Julia.

Soft real time is a term used to mean running code fast/frequently enough for timing to not practically matter.
It is important to note this approach makes none of the guarantees typically enforced by actual real-time systems.

Trade some robustness for substantial flexibility.


## 4ish Ingredients
```julia
@topic
@on x 
@onany (x,y,z)
@onall (x,y,z)
@every 3u"Hz"
@after 1u"s"
@loop
```



## Timing
- can be specified as internal units
- can be specified as unitful units
- should be specifiable as DateTime units






0. What are tasks?

A zero argument function that can be run (possibly asynchronously) and possibly interrupted.


1. Timing control (@after)

```julia
@after Second(10) println("starting thing")
@after Second(20) println("ending thing")
```

2. Repetition (@every, @at)

```julia
@every Hour(1) println("remember to take occasional breaks")
```

3. Data Sharing (@topic, @share)
```julia
@topic x = true
@share x = true
# x[] = 2
```

4. Reactivity (@on, @onall)
```julia
@on x println("x is now: $(x[])")
```

5. Extendability (@loop) 
```julia
@loop "task name" begin
    # task
end begin
    # finalizer
end
```

User has complete control of timing and task lifetime:
```julia
@loop begin
    isopen(serial) && error("serial port closed")
    x[] = parse(UInt16, readline(serial))
end begin #finalizer
    isopen(serial) && close(serial)
end
```




6. Utilities (stopping what you've started)
Tasks return handles, but sometimes we miss one.

```julia
RTk.status() # print a summary of active tasks 
RTk.overview()
RTk.list_tasks()
RTk.list_topics()
RTk.kill_all!()
```