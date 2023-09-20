
mutable struct UDPMulticast
    group::IPAddr
    port::Integer
    host::IPAddr
    socket::UDPSocket
    UDPMulticast(group, port; host = ip"0.0.0.0") = new(group, port, host)
end

# isopen(udp::UDPMulticast) = isdefined(udp, :socket) && any(udp.socket.status .== (3,4))
isopen(udp::UDPMulticast) = isdefined(udp, :socket) && any(Base.uv_status_string(udp.socket) .== ("open","active"))

function open(udp::UDPMulticast)
    if isopen(udp)
        @warn "UDPSocket is already open!"
    else
        udp.socket = UDPSocket()
        bind(udp.socket, udp.host, udp.port; reuseaddr = true)
        join_multicast_group(udp.socket, udp.group)
    end
    return udp
end

function close(udp::UDPMulticast)
    if isopen(udp)
        leave_multicast_group(udp.socket, udp.group)
        close(udp.socket)
    else
        @warn "UDPSocket is already closed!"
    end
    return udp
end

function show(io::IO, udp::UDPMulticast)
    print(io, "Multicast[")
    print(io, CR_GRAY("$(udp.group):$(udp.port)"), "] - ")
    print(io, crayon"bold"(isopen(udp) ? crayon"yellow"("[open]") : crayon"red"("[closed]")))
end


recvfrom(udp::UDPMulticast) = isopen(udp) ? recvfrom(udp.socket) : error("no connection")
recv(udp::UDPMulticast) = isopen(udp) ? recv(udp.socket) : error("no connection")
send(udp::UDPMulticast, msg) = isopen(udp) ? send(udp.socket, udp.group, udp.port, msg) : error("no connection")


# udp = MulticastGroup(ip"230.8.6.7", 5309)
# @every seconds(10) "heartbeat" begin
#     send(HEARTBEAT, 


# should only receive on 3
# can bind on 0,1
# can recv on 2,3
# can send on 0-4
# send on 1 -> sets to 4
# closed on 5+
# "active" should be 3


# const StatusUninit      = 0 # handle is allocated, but not initialized
# const StatusInit        = 1 # handle is valid, but not connected/active
# const StatusConnecting  = 2 # handle is in process of connecting
# const StatusOpen        = 3 # handle is usable
# const StatusActive      = 4 # handle is listening for read/write/connect events
# const StatusClosing     = 5 # handle is closing / being closed
# const StatusClosed      = 6 # handle is closed
# const StatusEOF         = 7 # handle is a TTY that has seen an EOF event (pretends to be closed until reseteof is called)
# const StatusPaused      = 8 # handle is Active, but not consuming events, and will transition to Open if it receives an event
# function uv_status_string(x)