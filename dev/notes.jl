# og Reactive.jl signal (julia 0.6? 0.7?)
mutable struct Signal{T}
    id::Int # also its index into `nodes`, and `edges`
    value::T
    parents::Tuple
    active::Bool
    actions::Vector{Function}
    preservers::Dict
    name::String
    function Signal{T}(v, parents, pres, name) where T
        id = length(nodes) + 1
        n=new{T}(id, v, parents, false, Function[], pres, name)
        push!(nodes, WeakRef(n))
        push!(edges, Int[])
        foreach(p->push!(edges[p.id], id), parents)
        finalizer(schedule_node_cleanup, n)
        n
    end
end
# push-based
# shared central channel of updates
# signals are typed



# Signals.jl
# signals are NOT typed
# entirely pull-based?
# on update, invalidate downstreams
# recalculates on pull & validates
# reuses value while valid
# this is smart (benchmark?)


# I want to make it *task* based, fundamentally