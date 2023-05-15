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




## ------------------------------------ controls example ------------------------------------ ##
using ReactiveToolkit
using LibSerialPort
# 1. create some signals
r = Signal{Float64}(0) # reference
x = Topic{UInt16}(0) # state
u = Topic{UInt16}(0) # input
# 2. connect to a serial port
port = SerialPort(name)
open(port)
# 3. monitor for updates to state
@always "serial monitor" begin
    x[] = parse(UInt16, readline(port))
end begin # finalizer (optional)
    isopen(port) && close(port)
end
# 4. keep device informed of u
@on u write(port, "$(u[])")
# 5. write a control law
@onany (x,r) begin
    u[] = round(UInt16, K*(x-r))
end
# 6. generate a reference signal
@at Hz(100) r[]=sin(2π*now())


## ------------------------------------ stissue force sensing pseudocode ------------------------------------ ##

pkt = NatNetPacket(read(port))
pkt.marker_points.z


## logging
xbuf = CircularBuffer{Float64}(100)

@on x begin
    push!(xbuf)
    isfull(xbuf) && @done
end





# calculate force
p = block.poly_force 
y = fetch(block.z_mm) - block.z_mm_0 #height
x = BVUtokV(fetch(block.v_mon)) #measured vref
mapped_force = @. p[1] + p[2]*x + p[3]*y + p[4]*x^2 + p[5]*x*y + p[6]*y^2 + p[7]*x^2*y + p[8]*x*y^2 + p[9]*y^3 + p[10]*x^2*y^2 + p[11]*x*y^3 + p[12]*y^4 + p[13]*x^2*y^3 + p[14]*x*y^4 + p[15]*y^5
put!(block.force_N, mapped_force)



function force_map(x,y)
    return p[1] +
    p[2]*x +
    p[3]*y +
    p[4]*x^2 +
    p[5]*x*y +
    p[6]*y^2 +
    p[7]*x^2*y +
    p[8]*x*y^2 +
    p[9]*y^3 +
    p[10]*x^2*y^2 +
    p[11]*x*y^3 +
    p[12]*y^4 +
    p[13]*x^2*y^3 +
    p[14]*x*y^4 +
    p[15]*y^5
end

1,x,y,x^2,x*y,y^2,x^2*y,x*y^2

@topic voltage = zeros(10,10).*u"kV"
@topic height = zeros(10,10).*u"mm"
@topic ref_voltage = zeros(10,10).*u"kV"

height0 = height[]
@at Hz(100) "force estimation" begin
    Δ = height[] .- height0
    v = voltage[]
    force[] = force_map.(Δ, v)
end

@on force "wand" begin
    ref_voltage[] = map(f->(f > 1.25u"N" ? 6u"kV" : 0u"kV"), force[])
end

for i in 1:10
    @at kHz(1) "mcu listener $i" begin
        push!(buffer, readbytes(mcus[i].port))
        if haspacket(buffer)
            height[i][] = decode(UInt16, nextpacket!(buffer))
        end
    end begin # finalizer
        isopen(mcu) && close(mcu)
    end
end

@onany height_raw begin

end

# pause notify! from taking effect
# mute(topic)
# unmute(topic)

write.(mcus, "HV ON")
write.(mcus, "HV OFF")

## ------------------------------------ stissue force sensing pseudocode ------------------------------------ ##

fmeas = map(1:800) do _
    sleep(0.001)
    force[]
end
fmean = [mean(f[x,y] for f in fmeas) for x in 1:10, y in 1:10]
grams = sum(map(x->x > 0.02 ? x : 0.0, abs.(fmean - base_force)))*(1000/9.8)
stotal = string(round(Int, grams))
V = zeros(5,10)
if length(stotal) > 2
    V[1:5,1:3] = displayNum(stotal[1])
    V[1:5,4:6] = displayNum(stotal[2])
    V[1:5,7:9] = displayNum(stotal[3])
elseif length(stotal) > 1
    V[1:5,4:6] = displayNum(stotal[1])
    V[1:5,7:9] = displayNum(stotal[2])
elseif length(stotal) == 1
    V[1:5,7:9] = displayNum(stotal[1])
end
z_ref[] = Int.(ceil.(12*V))


## ------------------------------------ stissue force sensing pseudocode ------------------------------------ ##


e[3] = e[2]
e[2] = e[1]
e[1] = Z_REF[] - Z_FILT[][6:10,1:10] # update error

v_ref[3] = v_ref[2]
v_ref[2] = v_ref[1]
v_ref[1] = 1*v_ref[2] + 20*(1*e[1] - 0.65*e[2]) # controller for 1st order, 200Hz

v_ref[1] = max.(v_ref[1], 0) # saturate bottom
v_ref[1] = min.(v_ref[1], 900) # saturate top

V_REF[][6:10,1:10] = Int.(ceil.(v_ref[1]))