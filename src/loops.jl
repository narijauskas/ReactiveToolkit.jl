
## ------------------------------------ task state ------------------------------------ ##

abstract type TaskState end

struct NoTask     <: TaskState end # there is no task
struct TaskActive <: TaskState end # task is currently runnable
struct TaskFailed <: TaskState end # task has crashed - see x.task for details
struct TaskDone   <: TaskState end # task has completed - most likely stopped manually via kill!(x)
#NOTE: may split TaskDone into TaskDone and TaskStopped/TaskKilled

TaskState(::Nothing) = NoTask()
TaskState(x) = isdefined(x, :task) ? istaskfailed(x.task) ? TaskFailed() : istaskdone(x.task) ? TaskDone() : TaskActive() : NoTask()
isactive(x) = TaskState(x) isa TaskActive
# isactive -> istaskactive ?
task_state(x) = TaskState(x)

show(io::IO, ::NoTask)     = print(io, "[no task]" |> crayon"bold" |> crayon"dark_gray")
show(io::IO, ::TaskActive) = print(io, "[active]"  |> crayon"bold" |> crayon"yellow")
show(io::IO, ::TaskFailed) = print(io, "[failed]"  |> crayon"bold" |> crayon"red")
show(io::IO, ::TaskDone)   = print(io, "[done]"    |> crayon"bold" |> crayon"blue")
## ------------------------------------ Conditions ------------------------------------ ##

struct NoCondition end #TODO: rename External
const ConditionUnion = Union{Threads.Condition, Condition, NoCondition}
#FUTURE: Have a RTkCondition type that holds upstreams for unlinking when task is done

abstract type AbstractTrigger end
mutable struct ExternalTrigger <: AbstractTrigger
end
mutable struct ConditionTrigger <: AbstractTrigger
    cond::Threads.Condition
end
mutable struct TimerTrigger <: AbstractTrigger
    dt::Nano
    t_next::Nano
end
TimerTrigger(dt::Nano) = TimerTrigger(dt, now()+dt)

## ------------------------------------ Loops ------------------------------------ ##
# Wrap *any* code into an infinite while loop scheduled to run forever on any available thread.
# This is a feature.

mutable struct LoopTask
    name::String
    trigger::AbstractTrigger
    # waitfor::WaitForAbstract
    @atomic enabled::Bool
    const t_start::Nano
    @atomic t_last::Union{Nano,Nothing}
    @atomic n_calls::Int
    #MAYBE: limit::Nano # throttle
    task::Task
    LoopTask(name, trig) = new(name, trig, true, now(), nothing, 0)
end

show_task_id(tk) = show_task_id(tk, TaskState(tk))
show_task_id( _, ::NoTask) = "[ --- no task --- ]" |> crayon"bold" |> crayon"dark_gray"
show_task_id(tk, ::TaskActive) = "[$(idstring(tk)) - active]" |> crayon"bold" |> crayon"yellow"
show_task_id(tk, ::TaskFailed) = "[$(idstring(tk)) - failed]" |> crayon"bold" |> crayon"red"
show_task_id(tk, ::TaskDone)   = "[$(idstring(tk))  -  done]" |> crayon"bold" |> crayon"blue"

function show(io::IO, tk::LoopTask) 
    print(io, show_task_id(tk))
    # print(io, "  LoopTask")
    # print(io, "[", CR_GRAY(idstring(tk)), "]")
    print(io, CR_BOLD(" \"$(tk.name)\""))
    # print(io, " - $(TaskState(tk))")
end

function show(io::IO, ::MIME"text/plain", tk::LoopTask)
    println(io, tk)
    # println(io, "    ", tk.task)
    println(io, "  made: $(tk.t_start |> ago)")
    println(io, "  runs: $(tk.n_calls)")
    println(io, "  last: $(isnothing(tk.t_last) ? "never" : tk.t_last |> ago)")
end

debug(tk::LoopTask) = tk.task
iscompact(io) = get(io, :compact, false)::Bool
idstring(tk::LoopTask) = isdefined(tk, :task) ? idstring(tk.task) : "???"
idstring(task::Task) = string(convert(UInt, pointer_from_objref(task)), base = 60)
# idstring(task::Task) = "@0x$(string(convert(UInt, pointer_from_objref(task)), base = 16, pad = Sys.WORD_SIZE>>2))"
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop), " - ", repr(TaskState(loop)))
# Base.show(io::IO, loop::Loop) = print(io, idstring(loop), " \"$(loop.name)\"")
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop))


isenabled(x) = isequal(x.enabled, true)

# function kill(::WaitForExternal, tk::LoopTask)
# rtk_warn("$tk is waiting on an external condition to complete. ",
#             "It will not be rescheduled, but will remain active until ",
#             "the task encounters an error or the condition is met once again.")
            # "consider implementing a custom WaitFor type and wait/notify/kill methods"
# end

# WaitForCondition
# WaitForAbstract
# WaitForTimer
# WaitForTopic
# WaitForExternal

# AbstractWait
# TopicWait
# TimerWait
# ExternalWait
# ConditionWait

# function kill(::ConditionTrigger, tk::LoopTask)
#     rtk_info("$tk has been asked to stop")
#     notify(tk, false) # notify task without calling user code
# end

# function kill(tk::LoopTask)
#     @atomic tk.enabled = false
#     if !isactive(tk)
#         rtk_warn("$tk is not active")
#     else
#         kill(tk.trigger, tk)
#     end
#     yield() # maybe. let the task quit, messages print
#     nothing
# end

function kill(tk::LoopTask)
    @atomic tk.enabled = false
    if !isactive(tk)
        rtk_warn("$tk is not active")
    elseif tk.trigger isa ExternalTrigger
        rtk_warn("$tk is waiting on an external condition to complete. ",
            "It will not be rescheduled, but will remain active until ",
            "the task encounters an error or the condition is met once again.")
            # "consider implementing a LoopCondition to automate this behavior"
    # elseif tk.condition isa CustomCondition
        # kill!(tk.condition) # user defined custom behavior
    else
        rtk_info("$tk has been asked to stop")
        notify(tk, false) # notify task without calling user code
    end
    yield() # maybe. let the task quit, messages print
    nothing
end

# document these as default fallbacks - maybe have them print a warning if called?
wait(trig::AbstractTrigger) = true
notify(trig::AbstractTrigger, arg=true; kw...) = nothing


wait(trig::ConditionTrigger) = @lock trig.cond wait(trig.cond)
notify(trig::ConditionTrigger, arg=true; kw...) = @lock trig.cond notify(trig.cond, arg; kw...)
# wait(trig::TimerTrigger) = sleep(0.001) #TODO: make this a bit more intelligent
# notify(trig::TimerTrigger, arg=true; kw...) = nothing

# notifying a task is really only used by the kill mechanisms
# does nothing by default
# ideally will unblock whatever the task is waiting on
notify(tk::LoopTask, arg=true; kw...) = notify(tk.trigger, arg; kw...)

# waiting on a task is dispatched by calling wait on the trigger
function wait(tk::LoopTask)
    if wait(tk.trigger)
        @atomic tk.n_calls += 1
        @atomic tk.t_last = now()
        return isenabled(tk)
    else
        return false
    end
end



## ------------------------------------ macro ------------------------------------ ##

macro loop(args...)
    _loop(args...)
end

_loop(name, loop)               = _loop(name, ExternalTrigger(), :(), loop, :())
_loop(name, init, loop, final)  = _loop(name, ExternalTrigger(), init, loop, final)
_loop(name, trig, loop)         = _loop(name, trig, :(), loop, :())

function _loop(name, trig, init_ex, loop_ex, final_ex)
    quote
        local tk = LoopTask($(esc(name)), $trig) # partially initialized
        tk.task = @spawn begin
            try
                rtk_info("$tk is starting")
                $(esc(init_ex)) # <- user defined initializer
                while isenabled(tk)
                    wait(tk) && $(esc(loop_ex)) # <- user defined loop runs if notify(tk, true)
                    yield()
                end
            catch e
                rtk_err("$tk has failed")
                rethrow(e)
            finally
                rtk_info("$tk has stopped")
                #TODO: unlink conditions
                $(esc(final_ex)) # <- user defined finalizer
            end
        end
        rtk_register(tk) # add to global task index
        yield() # allows the new loop task to run immediately. solid maybe
        tk # macro results in LoopTask object
    end
end


# @loop "serial listener" WaitForSerial() begin
#     readline(port) # blocking
# end

# function Base.kill(::WaitForSerial, tk::LoopTask)
#     rtk_info("$tk has been asked to stop")
#     close(tk.port)
#     notify(tk, false) # notify task without calling user code
# end