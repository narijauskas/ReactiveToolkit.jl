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

#------------------------------------ Generic Topics ------------------------------------#
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

function Topic(name, v::T) where {T}
    Topic{T}(name, v)
end

function Topic{T}(name, v) where {T}
    Topic{T}(name, convert(T, v))
end

function Topic{T}(name, v::T) where {T}
    cond = Threads.Condition()
    lock = ReentrantLock()
    Topic{T}(name, [v,v], 2, now(), 1, cond, lock)
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
            $(esc(name)) = Topic{$T}($("$name"), $value)
        end
    elseif @capture(ex, name_ = value_)
        quote
            $(esc(name)) = Topic($("$name"), $value)
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


#------------------------------------ Atomic/Local Topics ------------------------------------#

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

# notify(x::UDPTopic, arg=true; kw...) = @lock x.cond notify(x.cond, arg; kw...)

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
        trig = ConditionTrigger($(esc(x)).cond)
        @loop $(esc(name)) trig $(esc(init)) $(esc(loop)) $(esc(final))
    end
end


#------------------------------------ echo------------------------------------#

echo(x::AbstractTopic) = @on x "echo $(x.name)" println(x.name, ": ", x[])









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
