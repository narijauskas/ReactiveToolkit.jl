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
# rules:
# 1. no signals of signals
# 2. signals must have an initial value

#TODO: update constructors & docstrings
#NOTE: constructors may be redesigned


"""
    Signal{T} <: AbstractSignal{T}

The Signal type represents a time-variant quantity of type `T`, which can be safely shared by multiple threads. Stores values in a buffer of `(v,t)` pairs, where `v` is the value and `t` is a timestamp of when the `v` was written.
"""
mutable struct Signal{T} <: AbstractSignal{T}
    @atomic v::T
    @atomic t::Nanosecond
    @atomic active::Bool
    cond::Condition
    Signal{T}(v0::T) where {T} = new(v0, now())
    Signal{T}(v0) where {T<:Signal} = @error "cannot create Signals of Signals"
end
#TODO: add a condition



"""
    Signal(v0::T)

Create a `Signal{T}` with an initial value of `v0`
"""
Signal(v0::T) where {T} = Signal{T}(v0) # gets T from v0

"""
    Signal{T}(v0)
    
Create a `Signal{T}` with an initial value of `v0`, where `v0` is converted to `T`.
"""
Signal{T}(v0) where {T} = Signal{T}(convert(T, v0))

"""
    Signal{T}()

Create a `Signal{T}` with an initial value created by `null(T)`.
"""
Signal{T}() where {T} = Signal{T}(zero(T))



#MAYBE: use null() function as in previous implementations?




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


