module ReactiveToolkit

using Crayons
# printgr(s) = print(crayon"grey", s, crayon"default")
printcr(c::Crayon, xs...) = printcr(stdout::IO, c, xs...)
printcr(io::IO, c::Crayon, xs...) = print(io, crayon"bold", c, xs..., crayon"default", crayon"!bold")

# printgr(xs...) = printgr(stdout::IO, xs...)
# printgr(xs...) = print(crayon"gray", xs..., crayon"default")


using Base.Threads: @spawn, Condition
using Sockets # maybe not

#MAYBE: import Observables for compatibility? package extension?


# include("timing.jl")
include("nanos.jl") # timing.jl?
export Nanos, now
export nanos, micros, millis, seconds
export Hz, kHz, MHz, GHz


# include("topics.jl")
# export Topic # observable? # topic

# include("reactions.jl")
# export Reaction # ReactiveTask
# export @loop # always, repeat, spin
# export @on
# export stop! # kill, kill!, stop

#TODO:
#onany
#onall

# include("daemon.jl") # timing.jl
# export @at


#TODO:
# include("globals.jl")
# provides tools to list and manage tasks, topics and interfaces
# someday: generate system graph (at least for run triggering)
# maybe: utils.jl

# interfaces:
# HID, Serial, TCP, UDP, Channels
# accept, listen, read, write


# Signals (construction, notification, value)
# Timers (construction, notification, taskdaemon)
# ReactiveTasks (id, status, stop!(id))
# graph/overview display (link implicit connections manually)

# do we want to have something like
# sock = connect(8002)
# @on sock begin
# end
# struct SRTxPacket end
# Base.parse(::Type{SRTxPacket}, str::AbstractString) or decode(::Type{SRTxPacket}, bytes)


#TODO: close(topic)

# @loop "listener" begin
#     pkt = split(recv(sock)) # wait for message
#     if pkt[1] == "ACK" && pkt[2] == "X"
#         x[] = parse(eltype(x), pkt[3])
#     else
#         error("invalid packet")
#     end
# end

# close(port) ==> close all attached topics, kill listeners
# interface-specific topics with automatic listeners?
# abstract type ExternalTopic end
# SerialTopic
# HIDTopic
# TCPTopic
# UDPTopic


# port = NatNetPort(ip,port,etc) #= UDPPort with extra steps
# natnet = NatNetTopic("name", port) #= UDPTopic("name", port, NatNetPacket())

# task1: listen on udp port->udptopic{custom packet encoding}
# must user  define eg. decode(NatNetPacket, str/data) ??
# eg: udp_listener->UDPTopic{NatNetPacket}

# task2: interpret/deserialize data
# UDPTopic{SRTxPacket}->(V_REF::Topic{Matrix}, V_MON::Topic{Matrix})

# mcu = SerialPort("COM4")
# open(mcu)

# # PKT defines packet format: eg. SRTxPacket
# function stream(T, mcu, topics...)
#     write(mcu, "STREAM topics ...")
#     hid = HIDPort(mcu)
#     open(hid)

#     hid_recv = HIDTopic{T}(hid)
#     hid_send = HIDTopic{T}(hid)
    
#     @loop "HID listener $(deviceid(mcu))" begin
#         # parse SRTxPackets
#         hid_recv[] = decode(T, recv(hid))
#     end begin
#         isopen(mcu) && write(mcu, "END_STREAM")
#         isopen(hid) && close(hid)
#     end

#     @on hid_send "HID writer $(deviceid(mcu))" begin
#         isopen(hid) ? write(hid, encode(T, hid_send[])) : close()
#         # throw(SudokuException)
#     end

#     return hid_recv, hid_send
# end

#YO:
# foreach(mcu->stream(SRTxPacket, mcu, "V_REF", "V_MON"), dcus)

#MAYBE:
# single value
# x[]
# x[1]

# array indexing?
# x[1,1:10]

# struct/dict indexing?
# x.timestamp
# x["timestamp"]

# does this mean passing setindex/getindex as well as setproperty/getproperty/propertynames based on children?
# how would for v in V_MON work? vs for v in V_MON[], where V_MON[] returns an array

# @on hid_recv begin
#     pkt = hid_recv[]
#     x[][1,1:10] .= convert.(Int, parse.(UInt16, pkt[1:10]))
#     # y[] = convert(Int, parse(UInt16, pkt[2]))
#     # z[] = convert(Int, parse(UInt16, pkt[3]))
# end
# RTkSerial.print
# RTkHID

# uint16_t v_ref[10];
# RTkHID vref1;

# write(s, pkt)

# function end_stream(mcu, hid)
#     write(mcu, "END_STREAM")
#     close(hid)
# end


#= Issues:
    - how to handle Signals of Signals? (forbid)
    - how to schedule MIMO tasks? (onany/onall)
        - onany by default
        - how to notify only when all? onall
    - how to handle external inputs (eg. recv(UDPSocket))
        - maybe with a trait? Reactivity? Observability? Detectable?
        - maybe make it a type of signal


using Sockets
sock = UDPSocket()

function on(fn, sock)
    rt = ReactiveTask()


    while isopen(sock)
        fn(recv(sock))
    end

    return rt
end

close(sock)
=#

#= performance of a captured variable in closures
    does the compiler know the return type of a signal?

    https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured
    https://github.com/c42f/FastClosures.jl
    https://github.com/JuliaLang/julia/issues/964
    https://docs.julialang.org/en/v1/manual/types/#Type-Declarations-1
=#

end # module
