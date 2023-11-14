
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

