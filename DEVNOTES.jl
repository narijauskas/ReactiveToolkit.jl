# Topics are a way to share data between tasks.
@topic x = 0
@topic y::Number = 0
z = Topic{Float64}("z", 0)

# Their value can be acessed or changed using []:
x[] # returns 0
x[] = 1
x[] # returns 1

# The @on macro can be used to react to changes in a topic:
tk1 = @on x println("x is now $(x[])")

# The @ every macro can be used to schedule a task to run repeatedly:
tk2 = @every seconds(1) x[] = x[] + 1

tk2 = @every millis(50) y[] = sin(2π*now()*1e-9)
kill(tk2)


using UnicodePlots
using DataStructures

@topic buf = CircularBuffer{Float64}(1000)

x = Topic{Float64}(0; size=1000)
@on x push!(buf[], x[])

# buf = Topic{Float64}(0, size=1000)
# capacity is size+1 for locked write ptr.
# buf[:] = locked read of entire buffer?

lineplot(buf[:])

# getindex(::Topic, ::Colon)

# <iframe width="560" height="315" src="https://www.youtube.com/embed/VIDEO_ID?start=72&end=76" frameborder="0" allowfullscreen></iframe>


# make topics
@topic x = 0
@topic y::Number = 0

# use/update values with []
y[] = sin(x[])

# react to changes
@on x y[] = sin(x[])

@on y begin
    println("initializer")
end begin
    println("y is now $(y[])")
end begin
    println("finalizer")
end

# react to time
@every millis(50) x[] += 1

# set a value
x[] = 2

# dump the buffer
x[:] isa Vector{Int}


@spawn begin
    println("hello from thread $(Threads.threadid())")
    yield()
    println("hello from thread $(Threads.threadid())")
    yield()
    println("hello from thread $(Threads.threadid())")
    yield()
    println("hello from thread $(Threads.threadid())")
    yield()
end