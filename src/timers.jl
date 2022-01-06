

# managed by taskdaemon
#------------------------------------ taskdaemon/scheduler ------------------------------------#

#FUTURE: store tasks as a sorted binary search tree (AVLTree)
# for now, use `naive` implementation from SRTxBase


mutable struct TaskDaemon
    @atomic enabled::Bool
    timers::Vector{Timer}
    lock::ReentrantLock
    self::Ref{Task} # store the daemon's task (to tell if it's running/crashed/etc.)
end

global const taskdaemon = TaskDaemon(false, Timer[], ReentrantLock(), Ref{Task}())

#TODO start/stop self
function _taskdaemon_start()
    global taskdaemon
    @atomic taskdaemon.enabled = true
    
    taskdaemon.self = @spawn begin
        while taskdaemon.enabled
            lock(taskdaemon.lock) do
                for t in taskdaemon.timers
                    if now() >= t.t_last + Nanosecond(t.freq)
                        notify(t)
                    end
                end
            end
            yield()
        end
    end
end

function _taskdaemon_stop()
    global taskdaemon
    @atomic taskdaemon.enabled = false
end

function _taskdaemon_cycle()
    global taskdaemon
    lock(taskdaemon.lock) do
        if isempty(taskdaemon.timers)
            _taskdaemon_stop()
        elseif !taskdaemon.enabled
            _taskdaemon_start()
        end
    end
end

function _taskdaemon_add(t::Timer)
    global taskdaemon
    lock(taskdaemon.lock) do
        push!(taskdaemon.timers, t)
    end
end

function _taskdaemon_rm(t::Timer)
    global taskdaemon
    lock(taskdaemon.lock) do
        deleteat!(taskdaemon.timers, taskdaemon.timers .== t)
    end
end


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
        _taskdaemon_add(tx)
        return tx
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
