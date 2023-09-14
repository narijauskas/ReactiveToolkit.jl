

mutable struct MulticastGroup
    group::IPAddr
    port::Integer
    host::IPAddr
    socket::UDPSocket
    MulticastGroup(group, port; host = ip"0.0.0.0") = new(group, port, host, UDPSocket())
end

isopen(udp::MulticastGroup) = isdefined(udp, :socket) && 3 == udp.socket.status

function open(udp::MulticastGroup)
    if isopen(udp)
        @warn "UDPSocket is already open!"
    else
        udp.socket = UDPSocket()
        bind(udp.socket, udp.host, udp.port; reuseaddr = true)
        join_multicast_group(udp.socket, udp.group)
    end
    return udp
end

function close(udp::MulticastGroup)
    if isopen(udp)
        leave_multicast_group(udp.socket, udp.group)
        close(udp.socket)
    else
        @warn "UDPSocket is already closed!"
    end
    return udp
end

function show(io::IO, udp::MulticastGroup)
    print(io, "MulticastGroup($(udp.group), $(udp.port)) - ")
    print(io, crayon"bold", isopen(udp) ? crayon"green"("[open]") : crayon"red"("[closed]"))
end


recv(udp::MulticastGroup) = isopen(udp) && recv(udp.socket)
send(udp::MulticastGroup, msg) = isopen(udp) && send(udp.socket, udp.group, udp.port, msg)


# udp = MulticastGroup(ip"230.8.6.7", 5309)
# @every seconds(10) "heartbeat" begin
#     send(HEARTBEAT, 