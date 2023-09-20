abstract type AbstractTopic{T} end

mutable struct LocalTopic{T} <: AbstractTopic{T}
    @atomic v::T
    # @atomic t::Nano # last update time
    conditions::Vector{Condition} #MAYBE: atomic?
    LocalTopic{T}(v0) where {T} = new(v0, Condition[])
end

LocalTopic(v0::T) where {T} = LocalTopic{T}(v0)
LocalTopic{T}(v0) where {T <: LocalTopic} = @error "cannot create Topics of Topics"
LocalTopic{T}() where {T<:Number} = LocalTopic{T}(zero(T))
LocalTopic() = LocalTopic{Any}(nothing)

Base.eltype(::Type{LocalTopic{T}}) where {T} = T

show(io::IO, x::LocalTopic{T}) where {T} = print(io, "LocalTopic{$T}: $(x[])")

link!(x::LocalTopic, cond) = push!(x.conditions, cond)
link!(xs, cond) = foreach(x->link!(x, cond), xs)


# """
#     x[] = v
# Store a value `v` to a topic `x`, along with a timestamp?. Atomic, thread-safe.
#     x[] -> v
# Read and return `v`, the current value of topic `x`. Atomic, thread-safe.
# """

# @inline gettime(x::Topic) = x.t
@inline Base.getindex(x::LocalTopic) = x.v
#MAYBE: consider making getindex atomic as well. Slower but safer.
# Can we break the current setup? Maybe with something like push!(x[], 1)

@inline function Base.setindex!(x::LocalTopic, v)
    @atomic x.v = v
    # @atomic x.t = now()
    notify(x)
    # now() - tlast > throttle && notify(x)
    return v
end

function notify(x::LocalTopic, arg=nothing; kw...)
    sum(x.conditions; init = 0) do cond
        lock(cond) do
            notify(cond, arg; kw...)
        end
    end
end


# RTk.topics.led_state
# RTk.topics[:led_state]
# RTk.topics[5410]

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
    print(io, CR_BOLD(" \"$(x.name)\" "))
    print(io, "UDPTopic{$T}: $(x[])")
    println(io)
    # print(io, " - $(x.last_ip)")
    # println(io, " - $(x.last_t)")
    println(io, " ", x.udp)
    println(io, " ", x.listener)
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
decode(::Type{T}, bytes) where {T} = parse(T, String(bytes))

#------------------------------------ on macro ------------------------------------#

macro on(args...)
    _on(args...)
end

_on(x, loop)              = _on(x, "@on $x", :(), loop, :())
_on(x, init, loop, final) = _on(x, "@on $x", init, loop, final)
_on(x, name, loop)        = _on(x, name, :(), loop, :())

function _on(x, name, init, loop, final)
    quote
        # cond = Threads.Condition()
        # link!($(esc(x)), cond) # x can be any iterable of topics
        cond = $(esc(x)).cond
        @loop $(esc(name)) cond $(esc(init)) $(esc(loop)) $(esc(final))
    end
end













#------------------------------------ other ------------------------------------#
# function Base.notify(x::AbstractTopic, arg; kw...)
#     lock(x.cond) do
#         notify(x.cond, arg; kw...)
#     end
# end

# function Base.wait(x::AbstractTopic)
#     lock(x.cond) do
#         wait(x.cond)
#     end
# end

# function Sockets.recv(x::AbstractTopic)
#     wait(x)
#     return x[]
# end




# macro on(x, name, init, loop, final)
#     x = esc(x)
#     init = esc(init)
#     loop = esc(loop)
#     final = esc(final)
#     return quote
#         cond = Threads.Condition()
#         # push!($(x).cond, cond)
#         # @loop $name cond $(init) $(loop) $(final)
#         push!(($x).conditions, cond)
#         @loop $name cond $init $loop $final
#     end
# end


# macro on(x, loop)
#     _on(x, "@on $x", :(), loop, :())
# end

# macro on(x, name, loop)
#     _on(x, name, :(), loop, :())
# end

# macro on(x, init, loop, final)
#     _on(x, "@on $x", init, loop, final)
# end

# macro on(x, name, init, loop, final)
#     _on(x, name, init, loop, final)
# end



# macro on(x, init, loop, final)
#     name = "@on $x"
#     :(@on $(esc(x)) $name $(esc(init)) $(esc(loop)) $(esc(final)))
# end
# macro on(x, name, ex) :(@on $x $name () $ex ()) end
# macro on(x, ex) esc(:(@on $x () $ex ())) end



#TODO: onany/onall
# onany(f, xs...) # make a signal that waits for any, then notifies common?
# @onall (x,y,z) ...
# @onany (x,y,z) ...
# @on (x,y,z) ... # could just make xs iterable?
