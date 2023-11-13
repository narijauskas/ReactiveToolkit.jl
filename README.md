# ReactiveToolkit.jl


## What is this package?
- provides tools to facilite reactive, soft real-time programming in julia

useful for robotics, hardware interaction, and controls.



<!-- What is a task? -->
and, how does asyncrhonous programming work in julia?

<!--  What is metaprogramming? -->

## @every - Timed Repetition

@every

## Sharing Data (@topic)
sharing data between tasks

## Reactivity (@on)
reacting to tasks

## Extendability @loop
custom tasks
along with topics this is the basic building block of the package
`@on` and `@every` are implemented using `@loop`

## Stopping Tasks


## Utilities
rtk_tasks()
rtk_topics()
rtk_kill_all!()
rtk_clean()


Consider the task which monitors x and prints its value whenever it changes:
```julia
@on x "x monitor" println("x is now: $(x[])")
```

A useful design pattern is to wrap a commonly used task template in a constructor function.
We can then use and reuse this constructor to generate tasks with behavior that can be customized to a given context via its arguments. For example, this is how we imlement `ReactiveToolkit.echo`:

```julia
echo(x::AbstractTopic) = @on x "echo $(x.name)" println(x.name, ": ", x[])
```

```julia
@topic x = 0
echo_x = echo(x)
kill(echo_x)
```


## Examples
- arduino serial monitor
- stissue
- inverse pendulum?