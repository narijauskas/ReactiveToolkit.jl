using Base.Threads: @spawn, Condition

mutable struct Foo
    @atomic v
    @atomic isopen
    cond::Condition
end

Foo(v) = Foo(v, true, Condition())


Base.isopen(x::Foo) = (true == x.isopen)

function Base.close(x::Foo)
    @atomic x.isopen = false
    notify(x)
end

function Base.open(x::Foo)
    @atomic x.isopen = true
end

function Base.notify(x::Foo)
    lock(x.cond) do
        notify(x.cond)
    end
end

function Base.wait(x::Foo)
    lock(x.cond) do
        wait(x.cond)
    end
end


function on(f, x)
    @spawn try
        @info "starting"
        while isopen(x)
            wait(x)
            f()
        end
    finally
        @info "stopped"
    end
end




## ------------------------------------ test ------------------------------------ ##

on(x) do
    f(x)
end

on(foo) do
    @info "hello!"
end

onany() # wait for any to update
onall() # wait for all to update




## ------------------------------------ external input listeners ------------------------------------ ##
using Sockets
sock = UDPSocket()

function on(fn, x)
    while isopen(x)
        fn(recv(x))
    end
end

close(sock)

 

on(UDPSocket()) do bytes
    fn(bytes)
end


on(mcu) do bytes
    fn(bytes)
end