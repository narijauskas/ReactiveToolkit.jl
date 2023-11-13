# Future
more complete UDP support -> needs a generic serialization scheme for marshalling/unmarshalling
should also make a C/Cpp version of the serializer for use in micros

rework the task killing mechanism to be simpler, more extensible

color customizations?

if your code works with @spawn, it should work with @loop/@on/@every


launching other terminals (this may be too system-specific to be worth it)
piping between terminals and julia instances
will most likely be built on top of UDP


default values for topics
topics must always have a value - this will not change.
eltype(topic::Topic{T}) = T
In practice, a "no value" state creates too many downstream problems when tasks assume topic[] will return a value of type T for topics of type Topic{T}.
I *could* add a default(::T) function to allow users to specify a default value for a topic, but I'm not sure it's worth it.


Test with Makie - do we still need @looplocal
maybe add a @local macro that modifies the macro expansion of @loop to swap @spawn with @async?


Add a @once primitive for construction of one-shot tasks
Add a @after primitive as a one-shot version of @every

@onany and @onall

Do topics *need* multiple conditions?
Otherwise killing one task will kill all that depend on it.
How can we make modifications to the condition list thread-safe?

add to docs: Making topics and tasks in a for loop
How to make 100 publisher/subscriber interactions? 
Why not make publishers and subscribers in a loop?
Let's say we want 100 subscibers that all act differently on the same topic. This will take *hours* to set up in ROS. In `ReactiveToolkit`, it's just a few lines of code:

```julia
x = Topic("x", 0)
ys = [Topic("y$i", 0) for i in 1:100]
tasks = [(@on x y[] = x[] + i) for (y,i) in enumerate(ys)]
x[] = 0
getindex.(y) # returns [1,2,...,100]
# kill.(tasks)

# alternatively, if you want all the tasks to do the same thing:
tasks = [(@on x y[] = x[]) for y in ys]
x[] = 1
getindex.(y) # returns [1,1,...,1]
```
