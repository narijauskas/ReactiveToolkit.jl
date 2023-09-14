using Crayons
using Sockets
import Sockets: recv, send
import Base: show
import Base: isopen, open, close
using Base.Threads: @spawn

mutable struct Multicast
    group::IPAddr
    port::Integer
    host::IPAddr
    socket::UDPSocket
    Multicast(group, port; host = ip"0.0.0.0") = open(new(group, port, host))
end

isopen(udp::Multicast) = isdefined(udp, :socket) && isopen(udp.socket)

function open(udp::Multicast)
    if isopen(udp)
        @warn "UDPSocket is already open!"
    else
        udp.socket = UDPSocket()
        bind(udp.socket, udp.host, udp.port; reuseaddr = true)
        join_multicast_group(udp.socket, udp.group)
    end
    return udp
end

function close(udp::Multicast)
    if isopen(udp)
        leave_multicast_group(udp.socket, udp.group)
        close(udp.socket)
    else
        @warn "UDPSocket is already closed!"
    end
    return udp
end

function show(io::IO, udp::Multicast)
    print(io, "Multicast($(udp.group), $(udp.port)) - ")
    print(io, crayon"bold", isopen(udp) ? crayon"green"("[open]") : crayon"red"("[closed]"))
end


recv(udp::Multicast) = recv(udp.socket)
send(udp::Multicast, msg) = send(udp.socket, udp.group, udp.port, msg)


# udp = Multicast(ip"228.5.6.7", 6789)