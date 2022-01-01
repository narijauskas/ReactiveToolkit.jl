using Base.Threads: @spawn, Condition

mutable struct Bar
    @atomic v
    cond::Condition
end


function Base.notify(bar::Bar)
    lock(bar.cond) do
        notify(bar.cond)
    end
end

function Base.wait(bar::Bar)
    lock(bar.cond) do
        wait(bar.cond)
    end
end


#TODO: on