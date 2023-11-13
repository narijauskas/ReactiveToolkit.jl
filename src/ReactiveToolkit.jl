module ReactiveToolkit


using Crayons
using Sockets
using Sockets: InetAddr
using Unitful
using MacroTools: @capture
using Base.Threads: @spawn
export @spawn # because I got tired of doing this every time
using Base.Threads: Condition
import Dates
import Dates: canonicalize, Nanosecond

import Base: show
import Base: isless, *, +, -, /
import Base: sleep
import Base: wait, notify
import Base: setindex!, getindex
import Base: kill
import Base: isopen, open, close
import Sockets: send, recv, recvfrom


# export RTk

# module RTk
#     import ..INDEX
#     # index = INDEX


#     global PRINT_TO_REPL::Bool = true

#     # print_local!(b::Bool = true) = (global PRINT_TO_REPL; PRINT_TO_REPL = b)

#     function rtk_print(str...)
#         if PRINT_TO_REPL
#             println(repeat([""], 32)..., "\r", str...)
#         end
#     end
    
#     info(str...) = rtk_print(CR_INFO("rtk> "), str...)
#     warn(str...) = rtk_print(CR_WARN("rtk:warn> "), str...)
#     err(str...) = rtk_print(CR_ERR("rtk:error> "), str...)
# end



# using .RTk

# a representation of time
include("nanos.jl")
export now
export nanos, micros, millis, seconds # for now
export ago
# export Nano


# infinite while loops with extra steps
include("loops.jl")
export @loop
export kill
export task_state
# tk = @loop "uncomment to segfault julia" sleep(1)

# sharing data between tasks
include("topics.jl")
export Topic, UDPTopic
export listen!
export echo
export @on
export @topic
export _topic #temporary
#MAYBE: onall


# UDP multicast helpers for communication
include("udp.jl")
export UDPMulticast
export send, recv


# include("timing.jl")
# include("daemon.jl")
include("timers.jl")
export @every
#FUTURE: @in, @after


include("utils.jl")
export rtk_init
export rtk_tasks
export rtk_status
export rtk_print

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
