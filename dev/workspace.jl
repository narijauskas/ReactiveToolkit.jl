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


function monitor(port_name)
    sp = SerialPort(port_name)

    tk = @loop "$port_name monitor" begin
        open(sp)
    end begin
        println(stdout, readline(sp))
    end begin
        isopen(sp) && close(sp)
    end
    return tk, sp
end

task, port = monitor("COM3")
# either can be used to stop the task and close the port
kill(task)
close(port)
# task = monitor("dev/ttyUSB0")

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




## ------------------------------------ other ------------------------------------ ##

timingdaemon # stissue taskdaemon with tree sort and smarter sleep
observabledaemon # translate to makie, does everything looplocal, single-threaded? ObservableTopic


## ------------------------------------ DAQ ------------------------------------ ##
# struct DAQ
#     port?
#     topics?
# end

@topic pwm_freq=5u"kHz"

@on pwm_freq begin
    val = round(UInt16, pwm_freq[] |> u"Hz" |> ustrip)
    write(daq, "SET PWM_FREQ $val")
end


# how to achieve thread-safe, thread-efficient I/O?
# interfaces have read/write locks?
# maybe have global management of threadpool via @threadcall?


# Port/Link/Interface/IO/Channel/Hook/Transfer/Translate/Lane/Attach
ROSInterface()
SerialInterface()
# ObservableLink

# LinkROS

@topic vref=0.0


RecvHID
SendHID

roscore = ROSCore(...)
SendROS(roscore, :reference, Float32) # publish to rostopic
RecvROS(roscore, :reference, Float32) # subscribe to rostopic, react on callback
LinkROS(roscore, :reference, Float32) # publish & subscribe - effectively try to match state

vref |> LinkROS(:reference, Float32) # vref will publish/subscribe to :reference ROStopic, react to changes
vref |> LinkHID(dcus[1], :vref, UInt16) # how to set one-way?

hid_send(mcu1, :vref, UInt16) # how does this appear on micro?
ros_send()
rossend(roscore, :rostopic, Float32)



# micro
RTkHID.send(:vref, )

## ------------------------------------ UDP/Interfaces ------------------------------------ ##
#= Interface API
Interfaces handle their own control flow, so we treat them as pipes.
send(...) - transfer a packet to the interface
recv(...) - transfer a packet from the interface
send/recv - transfers a packet to/from interface

# close()
# open()/connect()/join()

abstract type Encoding end
encoded as string by default?
encode(T, ...)/decode(T, ...) - define (de)serialization for packet encoding T

=#

using Base.Threads: @spawn

using Sockets

using Sockets
group = ip"228.5.6.7"
socket = Sockets.UDPSocket()
bind(socket, ip"0.0.0.0", 6789)
join_multicast_group(socket, group)
tk = @spawn while isopen(socket)
    println(repeat(recv(socket)|>String, 3))
end
leave_multicast_group(socket, group)
close(socket)

##
map(1:100) do i
    tk = @async String(recv(socket))
    yield()
    t = @elapsed begin
        send(socket, group, 6789, "msg: $i")
        msg = fetch(tk)
    end
    return (msg,t)
end
##
using UUIDs
UUIDs.uuid4()
x = Topic{Int}(0)
map(1:100) do i
    tk = @async recv(x)
    yield()
    t = @elapsed begin
        x[] = i
        msg = fetch(tk)
    end
end

##

using Sockets
group = ip"228.5.6.7"
sock = Sockets.UDPSocket()
send(socket, group, 6789, "swag");
close(sock)

msg = Topic{String}("hello")
msg = Topic("hello")
N = Topic{Int}(3)

@topic msg = "hello"
@topic n = 3

# @udp n = 3

# how do we do map topics to ports?
# can we have a peer-to-peer registry? UDPMesh.jl
port = 6789
group = ip"228.5.6.7"
# host = ip"0.0.0.0" # all

function udp_listener(group, port)
    socket = Sockets.UDPSocket()
    Sockets.bind(socket, ip"0.0.0.0", port)
    join_multicast_group(socket, group)

    tk = @loop "udp listener" begin
        println(repeat(recv(socket)|>String, 3))
    end

end



# one "DMX universe" or "network" is a UDP group
# open handshake socket on port 0 or port 1 or something
# declare topics, add to registry, assign ports

# UUID<->IPv6 multicast group address?



## can I break it?
ts = Topic(0.1)
go = Topic(true)
z = Topic(rand(10000))

tk0 = let tx = now()
@spawn while go[]
    dt = now()-tx
    tx = now()
    println(dt, length(z[]))
    sleep(ts[])
end
end

tk1 = map(1:100) do i
    @spawn while go[]
        z[][i] += sin(z[][i+1])
        z[][i] -= cos(z[][i+1])
        sleep(ts[])
    end
end

tk2 = map(1:10) do i
    @spawn while go[]
        pop!(z[])
        sleep(ts[])
    end
end


tk3 = map(1:10) do i
    @spawn while go[]
        push!(z[], rand())
        sleep(ts[])
    end
end



bar(x::typeof(1.0u"s")) = "Float seconds"
bar(x::Quantity) = bar(x|>Float64|>u"s")
bar(x) = "nope"


T = typeof(1.0u"s")
ST = supertype(T)
SST = supertype(ST)



Hz
kHz
MHz

nanos
micros
millis
seconds

@in secs(1) println("hello!")
@in seconds(1) println("hello!")
@in 1u"s" println("hello!")