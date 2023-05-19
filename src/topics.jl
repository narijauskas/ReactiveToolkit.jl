abstract type AbstractTopic{T} end

mutable struct Topic{T} <: AbstractTopic{T}
    @atomic v::T
    @atomic t::Nano
    cond::Condition
    Topic{T}(v0) where {T} = new(v0, now(), Condition())
end

Topic(v0::T) where {T} = Topic{T}(v0)
Topic{T}(v0) where {T <: Topic} = @error "cannot create Topics of Topics"
Topic{T}() where {T} = @error "Topics must have a value"


#------------------------------------ read/write functionality ------------------------------------#

"""
    x[] = v
Store a value `v` to a topic `x`, along with a timestamp. Atomic, thread-safe.
"""
@inline function Base.setindex!(x::Topic, v)
    @atomic x.v = v
    @atomic x.t = now()
    notify(x)
    return v
end

"""
    x[] -> v
Read and return `v`, the current value of topic `x`. Atomic, thread-safe.
"""
@inline Base.getindex(x::Topic) = x.v
#MAYBE: consider making getindex atomic as well. Slower but safer.
# Can we break the current setup? Maybe with something like push!(x[], 1)

"""
    gettime(s)
Read the most recent timestamp of a topic. Atomic, thread-safe.
"""
@inline gettime(x::Topic) = x.t

#------------------------------------ notification functionality ------------------------------------#


function Base.notify(x::AbstractTopic)
    lock(x.cond) do
        notify(x.cond)
    end
end

function Base.notify(x::AbstractTopic, arg; kw...)
    lock(x.cond) do
        notify(x.cond, arg; kw...)
    end
end

function Base.wait(x::AbstractTopic)
    lock(x.cond) do
        wait(x.cond)
    end
end

function Sockets.recv(x::AbstractTopic)
    wait(x)
    return x[]
end

#------------------------------------ other ------------------------------------#

Base.eltype(::Type{Topic{T}}) where {T} = T

function Base.show(io::IO, x::Topic{T}) where {T}
    println(io, "Topic{$T}: $(x[])")
end



#= see tasks.jl

tk = on(x) do
    f(x)
end

=#

#=
#NOTE: temporary way to stop on() fxns


function on(f, x)
    @spawn try
        @info "starting"
        while isopen(x)
            wait(x)
            f()
        end
    finally
        @info "stopped"
    end
end


Base.isopen(x::AbstractTopic) = (true == x.isopen)

function Base.close(x::AbstractTopic)
    @atomic x.isopen = false
    notify(x)
end

function Base.open(x::AbstractTopic)
    @atomic x.isopen = true
end
=#