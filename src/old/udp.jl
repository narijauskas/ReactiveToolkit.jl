
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


#------------------------------------ UDP Topics ------------------------------------#


mutable struct UDPTopic{T} <: AbstractTopic{T}
    const name::String
    @atomic value::T
    @atomic t_last::Nano
    @atomic ip_last::Sockets.InetAddr
    const cond::Threads.Condition
    const udp::UDPMulticast
    listener::LoopTask
    function UDPTopic{T}(name, port, value) where {T}
        new{T}(name,
            convert(T, value),
            now(),
            InetAddr(Sockets.localhost, port),
            Threads.Condition(),
            UDPMulticast(ip"230.8.6.7", port),
        ) |> listen!
    end
end

UDPTopic(name, port, value::T) where {T} = UDPTopic{T}(name, port, value)

show(io::IO, x::UDPTopic{T}) where {T} = print(io, "UDPTopic{$T}: $(x[])")

function show(io::IO, ::MIME"text/plain", x::UDPTopic{T}) where {T}
    print(io, "UDPTopic{")
    print(io, CR_GRAY("$T"), "}")
    println(io, CR_BOLD(" \"$(x.name)\" "))
    # print(io, "UDPTopic{$T}: $(x[])")
    # println(io)
    # print(io, " - $(x.last_ip)")
    # println(io, " - $(x.last_t)")
    println(io, "  value: ", x.value)
    println(io, "  updated: ", x.t_last |> ago)
    println(io, "  source: $(x.ip_last.host):$(x.ip_last.port)")
    println(io, "  udp:  ", x.udp)
    println(io, "  task: ", x.listener)
end

function listen!(x::UDPTopic{T}) where {T}
    isdefined(x, :listener) && kill(x.listener)
    isopen(x.udp) || open(x.udp)
    x.listener = @loop "$(x.name) listener" begin
        #FUTURE: try/catch?
        ip, bytes = recvfrom(x.udp) # blocks
        @atomic x.value = decode(T, bytes)
        @atomic x.t_last = now()
        @atomic x.ip_last = ip
        notify(x)
    end
    return x
end

@inline Base.getindex(x::UDPTopic) = x.value

@inline function Base.setindex!(x::UDPTopic, v)
    @atomic x.value = v
    send(x.udp, encode(x.value))
    return x.value
end

wait(x::UDPTopic) = @lock x.cond wait(x.cond)
notify(x::UDPTopic, arg=true; kw...) = @lock x.cond notify(x.cond, arg; kw...)

encode(v::T) where {T} = "$v"
decode(::Type{String}, bytes) = String(bytes)
decode(::Type{T}, bytes) where {T<:Number} = parse(T, String(bytes))
# decode(::Type{T}, bytes) where {T} = T()
