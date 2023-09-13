
using ReactiveToolkit

## --------------------------- making topics --------------------------- ##
# a thread-safe container
# simple rule: only share data between tasks using topics

@topic x # Topic{Any} with a value of nothing
@topic x::Float64
@topic x = 1
@topic x::Float64 = 1
x = Topic(1)
x = Topic{Float64}(1)

## --------------------------- using topics --------------------------- ##

# topics can be used just like normal variables by using [] to get/set the value
# this syntax should be very familiar to users of Observables.jl

# use a value
x[] isa Int

# set a value
x[] = 2


## --------------------------- react to topics --------------------------- ##
# topics have one more trick: we can react to changes

@on x do_the_thing()
@on (x,y,z) do_the_thing() # on x, y, or z
@onany (x,y,z) do_the_thing()
@onall (x,y,z) do_the_thing()


## --------------------------- repeating tasks --------------------------- ##
# we aren't limited to reactions - can repeat on time

@at Hz(1)
@every Hz(1)
@every Minute(1)

# --------------------------- one-shot tasks --------------------------- #
# to run something once after a precise delay:

@after now()
@after Time("23:15:00")
@after Minute(1)
@after nanos(10)



@at Time("23:15:00")
@at now()

@in Minute(1)
@in nanos(10)


# note: can always also use @spawn task() to just schedule and run task() immediately
#=  can also use
@in seconds(0)
@at now()
=#


# --------------------------- advanced example --------------------------- #

@after Minute(1) begin
    i = 1
    task = @every Second(1) println!("hello #$(i+=1)")
    @after Second(10) kill!(task)
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














using Base.Threads
using Base.Threads: @spawn

function maketask()
    cond = Threads.Condition()
    fxn = ()->begin
        for ix in 1:10
            val = lock(cond.lock) do
                wait(cond)
            end
            println("value: $val")
        end
    end
    task = @spawn fxn()
    return task, cond
end

tk, cond = maketask()


tk
lock(cond.lock) do
    notify(cond, "foo"; error=true)
end

notify(cond, "yeet")

# on kill?
notify(cond)
notify(cond, STOP_TASK)
notify(cond, STOP_TASK; error = true)




function maketask()
    cond = Threads.Condition()
    fxn = ()->begin
        for ix in 1:10
            val = lock(cond.lock) do
                wait(cond)
            end
            println("value: $val")
        end
    end
    task = @spawn fxn()
    return task, cond
end


try
    
catch e
    e isa KillTaskException
end

