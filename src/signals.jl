#------------------------------------ AbstractSignal api ------------------------------------#


abstract type AbstractSignal{T} end


"""
    s[] = v
Set the value of the signal `s` to `v`, and update it's timestamp in a thread-safe manner.
"""
Base.setindex!(s::AbstractSignal, v) = setvalue!(s, v)


"""
    s[] -> v
Return the current value `v` of the signal `s` in a thread-safe manner.
"""
Base.getindex(s::AbstractSignal) = getvalue(s)

#FUTURE: look into type stability tests with @code_warntype, @inferred, @code_native, @benchmark
# ie, s[]::T for Signal{T}
#FUTURE: Base.eltype(s)


#------------------------------------ simple signal implementation ------------------------------------#


mutable struct Signal{T} <: AbstractSignal{T}
    @atomic v::T
    @atomic t::Nano
    Signal{T}(v0::T) where {T} = new(v0, now())
end
#TODO: add a condition

"""
    setvalue!(s, v)
Store a value `v` to a signal `s`, along with a timestamp. Atomic, thread-safe.
"""
@inline function setvalue!(s::Signal, v)
    @atomic s.v = v
    @atomic s.t = now()
    #TODO: notify condition on setvalue
    nothing
end

"""
    getvalue(s)
Read the current value of a signal. Atomic, thread-safe.
"""
@inline getvalue(s::Signal) = s.v

"""
    gettime(s)
Read the most recent timestamp of a signal. Atomic, thread-safe.
"""
@inline gettime(s::Signal) = s.t




#------------------------------------ AbstractSignal default wrapper implementation ------------------------------------#

#= #NOTE: this may change
     we assume that a typical AbstractSignal subtype contains a field `signal`::Signal{T}
    and here we forward the primary methods according to that assumption

    mutable struct ASignal{T} <: AbstractSignal{T}
        ...
        s::Signal{T}
    end
=#

@inline setvalue!(s::AbstractSignal, v) = setvalue!(s.signal, v)
@inline getvalue(s::AbstractSignal) = getvalue(s.signal)
@inline gettime(s::AbstractSignal) = gettime(s.signal)


