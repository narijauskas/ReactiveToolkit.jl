module ReactiveToolkit

using Crayons
using Base.Threads: @spawn, Condition
using Unitful

import Base: show
import Base: isless, *, +, -, /
import Base: sleep
import Base: wait, notify
import Base: kill

# a representation of time
include("nanos.jl")
export now
export nanos, micros, millis, seconds # for now
# export Nano

# infinite while loops with extra steps
include("loops.jl")
export @loop
# tk = @loop "uncomment to segfault julia" sleep(1)

# sharing data between tasks
include("topics.jl")
export Topic
export @on
# export @topic
#MAYBE: onall


# include("timing.jl")
include("daemon.jl")
export @every
#FUTURE: @in









CR_GRAY = crayon"black"
CR_BOLD = crayon"bold"
CR_INFO = crayon"bold"*crayon"magenta"
CR_WARN = crayon"bold"*crayon"yellow"
CR_ERR  = crayon"bold"*crayon"red"

#TODO: fully implement this, move to submodule
rtk_print(str...) = println(repeat([""], 32)..., "\r", str...)
rtk_info(str...) = rtk_print(CR_INFO("rtk> "), str...)
rtk_warn(str...) = rtk_print(CR_WARN("rtk:warn> "), str...)
rtk_err(str...) = rtk_print(CR_ERR("rtk:error> "), str...)

global const INDEX = Loop[]
global const LOCK = ReentrantLock()

function rtk_register(loop)
    global LOCK
    global INDEX
    lock(LOCK) do
        push!(INDEX, loop)
    end
    nothing
end

export rtk_index
rtk_index() = (global INDEX; return INDEX)

# include("utils.jl")
# provides tools to list and manage tasks, topics and interfaces
# someday: generate system graph (at least for run triggering)
# someday: get stats, like total number of calls, etc.
# export rtk_info
# export rtk_warn
# export rtk_status
# export rtk_loops
# export rtk_tasks
# export rtk_topics



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
