
using ReactiveToolkit

## --------------------------- making topics --------------------------- ##
# a thread-safe container
# simple rule: only share data between tasks using topics

@topic x # Topic{Any} with a value of nothing
@topic x::Float64
@topic x = 1
@topic x::Float64 = 1
x = Topic("x", 1)
x = Topic{Float64}("x", 1)

## --------------------------- using topics --------------------------- ##

# topics can be used just like normal variables by using [] to get/set the value
# this syntax should be very familiar to users of Observables.jl

# use a value
x[] isa Int
y = sin(x[])

# set a value
x[] = 2

# dump the buffer
x[:] isa Vector{Int}


## --------------------------- react to topics --------------------------- ##
# topics have one more trick: we can react to changes

@on x do_the_thing()
@on (x,y,z) do_the_thing() # on x, y, or z
@onany (x,y,z) do_the_thing()
@onall (x,y,z) do_the_thing()


## --------------------------- repeating tasks --------------------------- ##
# we aren't limited to reactions - can repeat on time

@at Hz(1) do_the_thing()
@every Hz(1) do_the_thing()
@every Minute(1) do_the_thing()

# --------------------------- one-shot tasks --------------------------- #
# to run something once after a precise delay:

@after now() do_the_thing()
@after Time("23:15:00") do_the_thing()
@after Minute(1) do_the_thing()
@after nanos(10) do_the_thing()



# @at Time("23:15:00")
# @at now()

# @in Minute(1)
# @in nanos(10)


# note: can always also use @spawn task() to just schedule and run task() immediately
#=  can also use
@in seconds(0)
@at now()
=#


# --------------------------- advanced example --------------------------- #

@after seconds(3) begin
    i = 0
    task = @every millis(5) println("hello #$(i+=1)")
    @after seconds(8) kill(task)
end

@topic j = 0
@after seconds(3) begin
    task = @every millis(5) println("hello! #$(j[]+=1)")
    @after seconds(3) kill(task)
end


# --------------------------- custom functionality --------------------------- #
# ie. roll your own scheduling

@loop "name" begin
    # code to repeat
end begin
    # finalizer
end




# for example, to create a simple serial monitor for debugging an Arduino:

using RealtimeToolkit
using LibSerialPort


function SerialMonitor(port::SerialPort)
    @loop "serial monitor" begin # initializer
        open(port)
    end begin # loop
        isopen(port) && error("serial port closed")
        println(readline(port)) # readline waits for data, governs timing
    end begin #finalizer
        isopen(port) && close(port)
    end
end

SerialMonitor(x) = SerialMonitor(SerialPort(x))



port = SerialPort("COM4")
monitor = SerialMonitor(port)


kill!(monitor)
# or
close(port)




