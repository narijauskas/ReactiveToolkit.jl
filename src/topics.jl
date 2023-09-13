abstract type AbstractTopic{T} end

mutable struct Topic{T} <: AbstractTopic{T}
    @atomic v::T
    # @atomic t::Nano # last update time
    conditions::Vector{Condition} #MAYBE: atomic?
    Topic{T}(v0) where {T} = new(v0, Condition[])
end

Topic(v0::T) where {T} = Topic{T}(v0)
Topic{T}(v0) where {T <: Topic} = @error "cannot create Topics of Topics"
Topic{T}() where {T<:Number} = Topic{T}(zero(T))
Topic() = Topic{Any}(nothing)

Base.eltype(::Type{Topic{T}}) where {T} = T

show(io::IO, x::Topic{T}) where {T} = print(io, "Topic{$T}: $(x[])")

link!(x::Topic, cond) = push!(x.conditions, cond)
link!(xs, cond) = foreach(x->link!(x, cond), xs)


# """
#     x[] = v
# Store a value `v` to a topic `x`, along with a timestamp?. Atomic, thread-safe.
#     x[] -> v
# Read and return `v`, the current value of topic `x`. Atomic, thread-safe.
# """

# @inline gettime(x::Topic) = x.t
@inline Base.getindex(x::Topic) = x.v
#MAYBE: consider making getindex atomic as well. Slower but safer.
# Can we break the current setup? Maybe with something like push!(x[], 1)

@inline function Base.setindex!(x::Topic, v)
    @atomic x.v = v
    # @atomic x.t = now()
    notify(x)
    # now() - tlast > throttle && notify(x)
    return v
end

function notify(x::AbstractTopic, arg=nothing; kw...)
    sum(x.conditions) do cond
        lock(cond) do
            notify(cond, arg; kw...)
        end
    end
end


#------------------------------------ on macro ------------------------------------#

macro on(args...)
    _on(args...)
end

_on(x, loop)              = _on(x, "@on $x", :(), loop, :())
_on(x, init, loop, final) = _on(x, "@on $x", init, loop, final)
_on(x, name, loop)        = _on(x, name, :(), loop, :())

function _on(x, name, init, loop, final)
    quote
        cond = Threads.Condition()
        link!($(esc(x)), cond) # x can be any iterable of topics
        @loop $name cond $(esc(init)) $(esc(loop)) $(esc(final))
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
