
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

# struct KillTaskException <: Exception end

## ------------------------------------ Loops ------------------------------------ ##
# Wrap *any* code into an infinite while loop scheduled to run forever on any available thread.
# This is a feature.

mutable struct LoopTask
    name::String
    condition::ConditionUnion #TODO: redo as AbstractTrigger
    @atomic enabled::Bool
    #FUTURE: @atomic n_calls::Int
    #FUTURE: @atomic last_t::Nano
    #MAYBE: limit::Nano # throttle
    task::Task
    LoopTask(name, cond) = new(name, cond, true)
end

function show(io::IO, tk::LoopTask) 
    print(io, CR_BOLD(" \"$(tk.name)\" "))
    print(io, "LoopTask")
    print(io, CR_GRAY("[", idstring(tk), "]"))
    print(io, " - $(TaskState(tk))")
end

# function show(io::IO, ::MIME"text/plain", tk::LoopTask)
#     print(io, tk, " - $(TaskState(tk))")
# end

iscompact(io) = get(io, :compact, false)::Bool
idstring(tk::LoopTask) = isdefined(tk, :task) ? idstring(tk.task) : "???"
idstring(task::Task) = string(convert(UInt, pointer_from_objref(task)), base = 60)
# idstring(task::Task) = "@0x$(string(convert(UInt, pointer_from_objref(task)), base = 16, pad = Sys.WORD_SIZE>>2))"
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop), " - ", repr(TaskState(loop)))
# Base.show(io::IO, loop::Loop) = print(io, idstring(loop), " \"$(loop.name)\"")
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop))


isenabled(x) = isequal(x.enabled, true)

function kill(tk::LoopTask)
    @atomic tk.enabled = false
    if !isactive(tk)
        rtk_warn("$tk is not active")
    elseif tk.condition isa NoCondition
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

function wait(tk::LoopTask)
    # tk.condition isa NoCondition && return true
    # lock(tk.condition) do
    #     return wait(tk.condition)
    # end

    tk.condition isa NoCondition || @lock tk.condition wait(tk.condition)
    # @atomic tk.n_calls += 1
    # @atomic tk.t_last = now()
    return true
end

function notify(tk::LoopTask, arg=nothing; kw...)
    tk.condition isa NoCondition && return
    lock(tk.condition) do
        notify(tk.condition, arg; kw...)
    end
end

## ------------------------------------ macro ------------------------------------ ##

macro loop(args...)
    _loop(args...)
end

_loop(name, loop)               = _loop(name, NoCondition(), :(), loop, :())
_loop(name, init, loop, final)  = _loop(name, NoCondition(), init, loop, final)
_loop(name, cond, loop)         = _loop(name, cond, :(), loop, :())

function _loop(name, cond, init_ex, loop_ex, final_ex)
    quote
        local tk = LoopTask($(esc(name)), $cond)
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

