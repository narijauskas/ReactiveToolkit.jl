using Base.Threads: @spawn, Condition

abstract type AbstractSignal{T}
end

mutable struct Signal{T} <: AbstractSignal{T}
    @atomic v::T
    @atomic t::Nanosecond
    @atomic open::Bool #FUTURE: this will change
    cond::Condition
    Signal{T}(v₀) where {T} = new(v₀, now(), true, Condition())
end

Signal(v₀::T) where {T} = Signal{T}(v₀)
Signal{T}(v₀) where {T<:Signal} = @error "cannot create Signals of Signals"


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

function Base.wait(x::AbstractSignal)
    lock(x.cond) do
        wait(x.cond)
    end
end

# on(x) do
    #f(x)
# end
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



#NOTE: temporary way to stop on() fxns

Base.isopen(x::AbstractSignal) = (true == x.isopen)

function Base.close(x::AbstractSignal)
    @atomic x.isopen = false
    notify(x)
end

function Base.open(x::AbstractSignal)
    @atomic x.isopen = true
end

#------------------------------------ extras ------------------------------------#

function Base.show(io::IO, x::Signal{T}) where {T}
    println(io, "Signal{$T}: $(x[])")
end
