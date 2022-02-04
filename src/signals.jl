abstract type AbstractSignal{T} end

mutable struct Signal{T} <: AbstractSignal{T}
    @atomic v::T
    @atomic t::Nanosecond
    cond::Condition
    Signal{T}(v₀) where {T} = new(v₀, now(), Condition())
end

Signal(v₀::T) where {T} = Signal{T}(v₀)
Signal{T}(v₀) where {T <: Signal} = @error "cannot create Signals of Signals"
Signal{T}() where {T} = @error "Signals must have a value"


#------------------------------------ read/write functionality ------------------------------------#

"""
    s[] = v
Store a value `v` to a signal `s`, along with a timestamp. Atomic, thread-safe.
"""
@inline function Base.setindex!(s::Signal, v)
    @atomic s.v = v
    @atomic s.t = now()
    notify(s)
    nothing # maybe return v?
end

"""
    s[] -> v
Read the current value of a signal. Atomic, thread-safe.
"""
@inline Base.getindex(s::Signal) = s.v

"""
    gettime(s)
Read the most recent timestamp of a signal. Atomic, thread-safe.
"""
@inline gettime(s::Signal) = s.t

#------------------------------------ notification functionality ------------------------------------#


function Base.notify(x::AbstractSignal)
    lock(x.cond) do
        notify(x.cond)
    end
end

function Base.notify(x::AbstractSignal, arg; kw...)
    lock(x.cond) do
        notify(x.cond, arg; kw...)
    end
end

function Base.wait(x::AbstractSignal)
    lock(x.cond) do
        wait(x.cond)
    end
end

function Sockets.recv(x::AbstractSignal)
    wait(x)
    return x[]
end

#------------------------------------ other ------------------------------------#

Base.eltype(::Type{Signal{T}}) where {T} = T

function Base.show(io::IO, x::Signal{T}) where {T}
    println(io, "Signal{$T}: $(x[])")
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


Base.isopen(x::AbstractSignal) = (true == x.isopen)

function Base.close(x::AbstractSignal)
    @atomic x.isopen = false
    notify(x)
end

function Base.open(x::AbstractSignal)
    @atomic x.isopen = true
end
=#