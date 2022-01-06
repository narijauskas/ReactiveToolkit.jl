

# managed by taskdaemon
#------------------------------------ taskdaemon/scheduler ------------------------------------#

#FUTURE: store tasks as a sorted binary search tree (AVLTree)
# for now, use `naive` implementation from SRTxBase


mutable struct TaskDaemon
    enabled::Bool
    timers::Vector{Timer}
    selftask::Union{Task,Nothing} # store the daemon's task (to tell if it's running/crashed/etc.)
end

#TODO start/stop selftask

#TODO: selftask loop:
@spawn begin
    for t in timers
        now() >= t.t_last + Nanosecond(t.freq)
    end
    yield()
end

#TODO: constructor
global taskdaemon = TaskDaemon()


#------------------------------------ timers ------------------------------------#
# timers are a special signal ()->t
# they get notified periodically by taskdaemon
# they hold the last runtime as a value

mutable struct Timer <: AbstractSignal{Nanosecond}
    @atomic t_last::Nanosecond
    @atomic freq::Hz
    @atomic open::Bool
    cond::Condition

    function Timer(hz::Hz)
        tx = new(now(), hz, false, Condition())
        #TODO: add to scheduler
    end

end


function Base.notify(x::Timer)
    if trylock(x.cond)
        notify(x.cond)
        unlock(x.cond)
        @atomic x.t_last = now()
    end
end

#TODO:
# destroy!(x::Timer)
# remove from taskdaemon


every(f, hz::Hz) = every(f, Timer(hz))

function every(f, t)
    @spawn try
        @info "starting"
        while isopen(t)
            wait(t)
            f()
        end
    finally
        @info "stopped"
    end
end
