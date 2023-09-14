# ReactiveToolkit.jl
A set of primitives which bring "soft real-time" functionality to Julia.



`Soft real time` is a term used to mean running code fast/frequently enough for timing to not practically matter. It is important to note this approach makes none of the guarantees typically enforced by actual real-time systems. **In other words, don't use this for your missile.**


However, by sacrificing some robustness, we can gain tremendous flexibility. This proves to be very useful:


blah blah

Trade some robustness for substantial flexibility.

## Design
With enough hand waving, this package can be described in several ways. The reality is somewhere in the middle:
- a multithreaded Observables.jl + precise timing primitives
- a set of macros to extend julia's Task system
- open-source, real-time Simulink



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

```julia
@on topic "name" task_ex
@on topic "name" init_ex task_ex final_ex
```

5. Extendability (@loop) 
```julia
@loop "name" task_ex
@loop "name" init_ex task_ex final_ex
@loop "name" begin
    # initializer expression
end begin
    # loop task expression
end begin
    # finalizer expression
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



## FUTURE

### One-Shots
One-shot tasks. `Loop`s that don't loop. Not too useful on their own, but act as a building block for other things. No initializer or finalizer option.
```julia
@once "name" task_ex
```

Delay a task, or the creation of a task using `@after`:
```julia
@after time "name" task_ex
```

Can be used alone or chained with other macros:
```julia
@after seconds(1) do_stuff()
@after seconds(1) @every seconds(1) do_stuff()
```

Loop execution time can be limited using the pattern:
```julia
tk1 = @on x println(x[])
tk2 = @after seconds(1) kill(tk1)
(tk1, tk2)
```

Wrapped for convenience into `@for`:
```julia
@for time "name" task_ex
```
Which can be used as follows:
```julia
(tk1, tk2) = @for seconds(10) @every Hz(10) println("is this annoying?")
```


### Interfaces
TCP/UDP/Serial utilities/helpers?

Print to other terminals. Maybe open a new terminal, paste in some code, it acts like a UDP-based rtk client/listener?
rtk_print prints text to a UDP or TCP port?
anything can listen in?

```julia
run(`wt julia`)
```