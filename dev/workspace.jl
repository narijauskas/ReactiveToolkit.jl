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


## ------------------------------------ UDP ------------------------------------ ##
using Sockets
sock = UDPSocket()
bind(sock, ip"0.0.0.0", 1672) # listen from all ip addresses at port 1672

send(sock, getipaddr(), 1672, "msg") # send to local ip address

localip = getipaddr()

@benchmark @sync begin
    @async recv(sock)
    yield()
    send(sock, localip, 1672, "1") # send to local ip address
end

@benchmark @sync begin
    @async recv(s1)
    yield()
    s1[] = 1
end


## ------------------------------------ Crayons ------------------------------------ ##
using Crayons

printgr(s) = print(crayon"gray", s, crayon"default")
printcr(c, s) = print(crayon"bold", c, s, crayon"default", crayon"!bold")
println(crayon"bold", crayon"red", "abcd", crayon"default")
println("abcd")





## ------------------------------------ globals ------------------------------------ ##
# module Foo
#     const t1::UInt64 = time_ns()
#     t2::UInt64 = time_ns()
#     t3 = time_ns()
     
#     now1() = time_ns() - t1
#     now2() = time_ns() - t2
#     now3() = time_ns() - t3
# end



## ------------------------------------ sockets ------------------------------------ ##
using Sockets

function tcp_server(port=2000)
    server = listen(port)
    @repeat "tcp server" begin
        sock = accept(server)
        println("Hello World\n")
    end begin
        isopen(server) && close(server)
    end
end

# errormonitor(@async begin
#     server = listen(2000)
#     while true
#         sock = accept(server)
#         println("Hello World\n")
#     end
# end)





## ------------------------------------ serial monitor ------------------------------------ ##
using ReactiveToolkit
using LibSerialPort

function serial_io(name)
    sp = SerialPort(name)
    open(sp)

    @repeat "serial monitor" begin
        println(stdout, readline(sp))
    end begin
        isopen(sp) && close(sp)
    end

    console = Signal{String}("")

    @on console begin
        write(sp, console[]*"\n")
    end

    return console, sp
end

console, port = serial_io("COM6")
# serial port 
# open serial port
# repeat "serial monitor" begin
    # println(readline(sp))
