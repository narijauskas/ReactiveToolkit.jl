module ReactiveToolkit

using Crayons
using MacroTools: @capture
using Base.Threads: Condition
using Base.Threads: @spawn
export @spawn

import Dates
import Dates: canonicalize, Nanosecond

import Base: show
import Base: isless, *, +, -, /
import Base: sleep
import Base: wait, notify
import Base: setindex!, getindex
import Base: kill
import Base: isopen, open, close

# only needd for UDP
# using Sockets
# using Sockets: InetAddr
# import Sockets: send, recv, recvfrom

# a representation of time
include("timing.jl")
export now, ago
export nanos, micros, millis, seconds # for now
# export Nano

# sharing data between tasks
include("topics.jl")
export Topic
export @topic

# reactive task type
include("tasks.jl")
# export ReactiveTask
export task_state
export isactive
# export debug

# infinite while loops with extra steps
include("loops.jl")
export @loop
export kill
# tk = @loop "uncomment to segfault julia" sleep(1)

include("on.jl")
export echo
export @on
#MAYBE: onall

include("every.jl")
export @every
#FUTURE: @in, @after

# UDP multicast helpers for communication
#TODO: remove UDP dependency for now
# include("udp.jl")
# export UDPMulticast
# export send, recv
# export UDPTopic
# export listen!

# include("timing.jl")
# include("daemon.jl")



include("utils.jl")
export rtk_init
export rtk_tasks
export rtk_status
export rtk_print

# kill_all
# clean

# provides tools to list and manage tasks, topics and interfaces
# someday: generate system graph (at least for run triggering)
# someday: get stats, like total number of calls, etc.
# export rtk_info
# export rtk_warn
# export rtk_status
# export rtk_loops
# export rtk_tasks
# export rtk_topics

# export echo
# echo(x) = @on x println(x[])



#MAYBE: close(topic)





















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
