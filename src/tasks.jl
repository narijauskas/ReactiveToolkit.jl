## ------------------------------------ task state ------------------------------------ ##

abstract type TaskState end

# task is currently runnable
struct TaskActive <: TaskState end

# task has crashed - see x.task for details
struct TaskFailed <: TaskState end

# task has completed - most likely stopped manually via kill!(x)
struct TaskDone <: TaskState end


function TaskState(x)
    if istaskfailed(x.task)
        return TaskFailed()
    elseif istaskdone(x.task)
        return TaskDone()
    else
        return TaskActive()
    end
end

#TODO: colors
Base.show(io::IO, ::TaskActive) = print(io, "[active]")
Base.show(io::IO, ::TaskFailed) = print(io, "[failed]")
Base.show(io::IO, ::TaskDone)   = print(io, "[done]")





## ------------------------------------ reactive tasks ------------------------------------ ##

global taskid = 0x0000

mutable struct ReactiveTask
    enabled::Bool
    id::UInt16
    task::Task
    # cond::Condition # inherited from signal
    # ? - name::Union{String,Nothing}
    ReactiveTask() = new(true, (global taskid+=0x01))
    # link condition from signal, assign unique taskid, assign task later
    #FUTURE: register globally
end

isenabled(rt::ReactiveTask) = rt.enabled

disable!(rt::ReactiveTask) = setproperty!(rt, :enabled, false), return rt


#TODO: get stacktrace via rt.task

function Base.show(io::IO, rt::ReactiveTask)
    print(io, "ReactiveTask $(rt.id) - $(TaskState(rt))")
end





## ------------------------------------ starting/stopping tasks ------------------------------------ ##
#x::Signal?
function on(f::Function, x)
    rt = ReactiveTask()

    rt.task = @spawn try
        @info "starting task $(rt.id)"
        while isenabled(rt)
            wait(x)
            f()
            # or f(recv(x)) ?
        end
    # catch
        # @info "task $(rt.id) failed"
    finally
        @info "task $(rt.id) stopped"
    end

    return rt
end


function on(f::Function, x::UDPSocket)
    rt = ReactiveTask()

    rt.task = @spawn try
        @info "starting task $(rt.id)"
        while isopen(x)
            f(recv(x))
        end
    # catch
        # @info "task $(rt.id) failed"
    finally
        @info "task $(rt.id) stopped"
    end

    return rt
end

#=
Reaction(@spawn begin
    ...
end)
=#

function disable!(rt)
    rt.enabled = false
    # notify(rt.cond) can cause unintended updates to other tasks that depend on the same signal
    return rt
end


function every(f, freq)
    # ...
    return rt
end

## ------------------------------------ global overview/graph ------------------------------------ ##

#TODO: register task on creation

#TODO: stop!(taskid)/disable!
# lookup & stop

#TODO: show task overview as a list
#TODO: show task + signal overview as a graph

#TODO: purge!() - remove done/failed tasks

#TODO: destroy!(taskid)
# deregister globally

## ------------------------------------ other ------------------------------------ ##


# function on(f, x)
#     @spawn try
#         @info "starting"
#         while isopen(x)
#             wait(x)
#             f()
#         end
#     finally
#         @info "stopped"
#     end
# end