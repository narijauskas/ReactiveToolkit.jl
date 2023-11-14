# Examples and Design Patterns

## Topics vs Captured Variables

As a closure:
```julia
@after seconds(3) begin
    i = 0
    task = @every millis(5) println("hello! i=$(i+=1)")
    @after seconds(3) kill(task)
end
# i is not defined
```

As a topic:
```julia
@topic j = 0
@after seconds(3) begin
    task = @every millis(5) println("hello! j[]=$(j[]+=1)")
    @after seconds(3) kill(task)
end
# j[] is 600
```


## Topic/Task Generators
Sometimes we want lots of tasks that are almost identical, but with different parameters. Why not use a loop to build them?



## Topics: @topic

allowing values of type T to be safely and efficiently shared between parts of the system running on multiple threads.


```julia
@topic x = 10
@topic x::Int = 10
```
`@topic` is a macro ultimately creates an object of type `Topic{T}`.

A topic is a threadsafe container holding values of type T. In the example above, `x` is a `Topic{Int}`.

Note that `x` represents the container itself. We need a bit of extra syntax to access the value inside, which looks like this:
```julia
x[] = 1 # set the value of x
sin(x[]) # use the value of x
```



T can be anything you can represent in julia: primitive types like `UInt16`, abstract types like `Number`, dicts or structs encoding custom message types, variable length arrays, images, simulation models, symbolic differential equations, or even julia source code. It can also be of type `Any`.

```julia
@topic x = Trajectory{}
```
```julia
@topic x::Int = 10.0 # x holds Int64s, with initial value of 10
@topic y::Number = 10.0 # y holds Numbers, initially the Float64 10.0
@topic z::Number = 10 # 
@topic a::Any = 10.0

a[] = plot(rand(10))
```


## Custom Message Types
```julia
struct RobotStatus
    battery_level::Float64
    is_ok::Bool
end

@topic status = RobotStatus(100, true)
```

For more flexible messages:
```julia
@topic status = Dict("battery_level"=>100, "is_ok"=>true)
```


## Automatic Plotting
If we lean into the abstraction, we can do things like this:
```julia
using ReactiveToolkit
using CairoMakie

@topic fig = Figure()

let i = 1
    @on fig "autosave" begin
        save("./plots/figure_$i.png", fig[])
        i+=1
    end
end

@on data "autoplot" begin
    fig[] = lines(data[])
end

# now we can automatically plot and save data simply by storing it:
data[] = rand(10)

```