
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

show(io::IO, ::NoTask)     = print(io, "[no task]" |> crayon"bold" |> crayon"dark_gray")
show(io::IO, ::TaskActive) = print(io, "[active]"  |> crayon"bold" |> crayon"yellow")
show(io::IO, ::TaskFailed) = print(io, "[failed]"  |> crayon"bold" |> crayon"red")
show(io::IO, ::TaskDone)   = print(io, "[done]"    |> crayon"bold" |> crayon"blue")
## ------------------------------------ Conditions ------------------------------------ ##

struct NoCondition end #TODO: rename External
const ConditionUnion = Union{Threads.Condition, Condition, NoCondition}
#FUTURE: Have a RTkCondition type that holds upstreams for unlinking when task is done

abstract type AbstractTrigger end
mutable struct ExternalTrigger  <: AbstractTrigger
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
    @atomic enabled::Bool
    const t_start::Nano
    @atomic t_last::Union{Nano,Nothing}
    @atomic n_calls::Int
    #MAYBE: limit::Nano # throttle
    task::Task
    LoopTask(name, trig) = new(name, trig, true, now(), nothing, 0)
end

function show(io::IO, tk::LoopTask) 
    print(io, "LoopTask")
    print(io, "[", CR_GRAY(idstring(tk)), "]")
    print(io, CR_BOLD(" \"$(tk.name)\""))
    print(io, " - $(TaskState(tk))")
end

function show(io::IO, ::MIME"text/plain", tk::LoopTask)
    println(io, tk)
    # println(io, "    ", tk.task)
    println(io, "  made: $(tk.t_start |> ago)")
    println(io, "  runs: $(tk.n_calls)")
    println(io, "  last: $(isnothing(tk.t_last) ? "never" : tk.t_last |> ago)")
end

iscompact(io) = get(io, :compact, false)::Bool
idstring(tk::LoopTask) = isdefined(tk, :task) ? idstring(tk.task) : "???"
# idstring(task::Task) = string(convert(UInt, pointer_from_objref(task)), base = 60)
idstring(task::Task) = "@0x$(string(convert(UInt, pointer_from_objref(task)), base = 16, pad = Sys.WORD_SIZE>>2))"
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop), " - ", repr(TaskState(loop)))
# Base.show(io::IO, loop::Loop) = print(io, idstring(loop), " \"$(loop.name)\"")
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop))


isenabled(x) = isequal(x.enabled, true)

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

wait(trig::AbstractTrigger) = true
notify(trig::AbstractTrigger, arg=true; kw...) = nothing
wait(trig::ConditionTrigger) = @lock trig.cond wait(trig.cond)
notify(trig::ConditionTrigger, arg=true; kw...) = @lock trig.cond notify(trig.cond, arg; kw...)
# wait(trig::TimerTrigger) = sleep(0.001) #TODO: make this a bit more intelligent
# notify(trig::TimerTrigger, arg=true; kw...) = nothing

notify(tk::LoopTask, arg=true; kw...) = notify(tk.trigger, arg; kw...)
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
        local tk = LoopTask($(esc(name)), $trig)
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
        tk # macro results in loop object
    end
end




# macro loop(name, ex) :(@loop $name () $ex ()) end
# macro loop(name, cond, ex) :(@loop $name $cond () $ex ()) end
# macro loop(name, init_ex, loop_ex, final_ex) :(@loop $name NoCondition() $init_ex $loop_ex $final_ex) end
# macro loop(name, cond, init_ex, loop_ex, final_ex)
#     quote
#         loop = Loop($name, $cond)
#         loop.task = @spawn begin
#             try
#                 rtk_info("starting $loop")
#                 $(esc(init_ex))
#                 wait(loop)
#                 while isenabled(loop)
#                     $(esc(loop_ex))
#                     yield()
#                     wait(loop)
#                 end
#             catch e
#                 rtk_warn("$loop failed")
#                 rethrow(e)
#             finally
#                 rtk_info("$loop finished")
#                 $(esc(final_ex))
#             end
#         end
#         rtk_register(loop) # push!(ReactiveToolkit.index, loop)
#         yield() # allows the spawned loop task to run immediately. solid maybe
#         # return loop
#         loop
#     end
# end



# macro loop(name, loop_ex)
#     _loop(name, NoCondition(), :(), loop_ex, :())
# end

# macro loop(name, init_ex, loop_ex, final_ex)
#     _loop(name, NoCondition(), init_ex, loop_ex, final_ex)
# end

# macro loop(name, cond, init_ex, loop_ex, final_ex)
#     _loop(name, cond, init_ex, loop_ex, final_ex)
# end

# macro loop(name, cond, loop_ex)
#     _loop(name, cond, :(), loop_ex, :())
# end

