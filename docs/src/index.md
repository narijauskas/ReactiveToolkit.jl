# ReactiveToolkit.jl

## Signals

```julia
x = Signal(1)
x[] = 2 # set value (and notify)
x[] # return value
```

Thread safe.


```julia
wait(x)
notify(x)
```

## Reactions


All: `while(isactive(rxn))`

Base primitive:

```julia
rxn = @reaction "name" begin
    # custom wait, eg. recv(socket)
    # ...
end
```

These generate a `wait()` condition:

```julia
rxn = @on(xs...) do
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
rxn = @every(hz) do
    #...
end

@at Hz(1) println("hello")
@at Hz(1) "printer" begin
    println("hello")
end

```


### Stopping Reactions
```julia
stop!(rxn)
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

```julia
RTk.list() # list of running tasks along with index #
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
name!(rxn, name::String)
isactive(rxn)
RTk.daemon() # handles timing
```

## Operators

* map/map!
* foldp


## Future
Check out [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl)