abstract type AbstractTopic{T} end

# for all topics:
# """
#     x[] = v
# Store a value `v` to a topic `x`, along with a timestamp?. Atomic, thread-safe.
#     x[] -> v
# Read and return `v`, the current value of topic `x`. Atomic, thread-safe.
# """
#=
making topics:
@topic x::Int = 0
@topic x = 0

=#

#------------------------------------ Topics ------------------------------------#
# implemented with a reentrant lock and a 2-element circular buffer

mutable struct Topic{T} <: AbstractTopic{T}
    const name::String
    const buffer::Vector{T}
    const capacity::Int
    @atomic t_last::Nano
    @atomic rptr::Int # read pointer
    const cond::Threads.Condition
    const lock::ReentrantLock
end


# Topic(name, v::T) where {T} = Topic{T}(name, v)
# Topic{T}(name, v::T) where {T} = Topic{T}(name, convert(T, v))

function Topic(v::T; kw...) where {T}
    Topic{T}(v; kw...)
end

function Topic{T}(v; kw...) where {T}
    Topic{T}(convert(T, v); kw...)
end

function Topic{T}(v::T; size=10, name="topic") where {T}
    cond = Threads.Condition()
    lock = ReentrantLock()
    buf = repeat([v], size+1)
    Topic{T}(name, buf, size+1, now(), 1, cond, lock)
    # MAYBE: register topic globally?
end

#= Topics must have a value.
We could implement topics to hold Union{T,Nothing} values, 
or return Nothing if empty. However, this ends up creating
a lot of downstream errors from code that can't handle
Nothing types.
=#


# Quasihomoiconicity

macro topic(ex)
    _topic(ex)
end

function _topic(ex)
    if @capture(ex, name_::T_ = value_)
        quote
            $(esc(name)) = Topic{$T}($(esc(value)); name = $("$name"))
        end
    elseif @capture(ex, name_ = value_)
        quote
            $(esc(name)) = Topic($(esc(value)); name = $("$name"))
        end
    else
        quote
            error("invalid topic definition")
        end
    end
end

@inline function getindex(x::Topic)
    @inbounds return x.buffer[x.rptr]
end

@inline function getindex(x::Topic, ::Colon)
    # mutual exclusion enforced
    @lock x.lock begin
        r = x.rptr
        c = x.capacity
        idx = (r == c ? [r:-1:2;] : [r:-1:1; c:-1:r+2])
        return @inbounds x.buffer[idx]
    end
end

@inline function setindex!(x::Topic{T}, value) where T
    setindex!(x, convert(T, value))
end

@inline function setindex!(x::Topic{T}, value::T) where T
    @lock x.lock begin
        wptr = (x.rptr >= x.capacity ? 1 : x.rptr + 1)
        @inbounds x.buffer[wptr] = value
        @atomic x.t_last = now()
        @atomic x.rptr = wptr
        notify(x)
    end
    return x[]
end

@inline function wait(x::Topic)
    @lock x.cond wait(x.cond)
end

@inline function notify(x::Topic, arg=true; kw...)
    @lock x.cond notify(x.cond, arg; kw...)
end

function show(io::IO, x::Topic{T}) where {T}
    print(io, "Topic{$T}: $(x[])")
end

Base.eltype(::Type{Topic{T}}) where {T} = T
Base.length(x::Topic) = x.capacity - 1

# for multiple conditions:
# sum(x.conditions; init = 0) do cond
#     @lock cond notify(cond, arg; kw...)
# end


#= what's better?
option 1:
    lock(x.lock)
    try
        stuff
    finally
        unlock(x.lock)
    end

option 2:
    @lock x.lock stuff
=#






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





#TODO: onany/onall
# onany(f, xs...) # make a signal that waits for any, then notifies common?
# @onall (x,y,z) ...
# @onany (x,y,z) ...
# @on (x,y,z) ... # could just make xs iterable?
