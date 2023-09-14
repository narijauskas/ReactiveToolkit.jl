using Crayons
using Sockets
import Sockets: recv
import Base: show
import Base: isopen, open, close
using Base.Threads: @spawn

mutable struct NatNetClient
    socket::UDPSocket
    group::IPAddr
    port::Integer
    host::IPAddr
    natnet_version::VersionNumber
end

function NatNetClient(;
        group::IPAddr = ip"239.255.42.99",
        port::Integer = 1511,
        host::IPAddr = ip"0.0.0.0",
        natnet_version = v"3.0.0",
    )
    socket = UDPSocket()
    bind(socket, host, port)
    join_multicast_group(socket, group)
    return NatNetClient(socket, group, port, host, natnet_version)
end

function show(io::IO, client::NatNetClient)
    print(io, "NatNetClient[$(client.group):$(client.port)] - ")
    print(io, crayon"bold", isopen(client) ? crayon"green"("[open]") : crayon"red"("[closed]"))
end

recv(client::NatNetClient) = recv(client.socket)

#FUTURE:
function recv(client::NatNetClient)
    decode_natnet(recv(client.socket), client.natnet_version)
end

function decode_natnet(pkt, version)
    try
        _decode_natnet(pkt, version)
    catch
        @warn "failed to decode packet!"
        pkt
    end
end

isopen(client::NatNetClient) = isopen(client.socket)
function close(client::NatNetClient)
    if isopen(client.socket)
        leave_multicast_group(client.socket, client.group)
        close(client.socket)
    else
        @warn "NatNetClient is already closed!"
    end
    return client
end

function open(client::NatNetClient)
    if isopen(client.socket)
        @warn "NatNetClient is already open!"
    else
        client.socket = UDPSocket()
        bind(client.socket, client.host, client.port)
        join_multicast_group(client.socket, client.group)
    end
    return client
end

client = NatNetClient()
task = @spawn recv(client)