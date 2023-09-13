
## ------------------------------------ task state ------------------------------------ ##

abstract type TaskState end

struct NoTask     <: TaskState end # there is no task
struct TaskActive <: TaskState end # task is currently runnable
struct TaskFailed <: TaskState end # task has crashed - see x.task for details
struct TaskDone   <: TaskState end # task has completed - most likely stopped manually via kill!(x)
#NOTE: may split TaskDone into TaskDone and TaskStopped/TaskKilled

TaskState(::Nothing) = NoTask()
TaskState(x) = istaskfailed(x.task) ? TaskFailed() : istaskdone(x.task) ? TaskDone() : TaskActive()
isactive(x) = TaskState(x) isa TaskActive

Base.show(io::IO, ::NoTask)     = print(io, "[no task]" |> crayon"bold" |> crayon"black")
Base.show(io::IO, ::TaskActive) = print(io, "[active]" |> crayon"bold" |> crayon"yellow")
Base.show(io::IO, ::TaskFailed) = print(io, "[failed]" |> crayon"bold" |> crayon"red")
# Base.show(io::IO, ::TaskDone)   = printcr(io, crayon"blue",   "[done]")
Base.show(io::IO, ::TaskDone)   = print(io, "[done]" |> crayon"bold" |> crayon"blue")




# struct KillTaskException <: Exception end

## ------------------------------------ Loops ------------------------------------ ##
# Wrap *any* code into an infinite while loop scheduled to run forever on any available thread.
# This is a feature.

# struct ExternalCondition
#     @atomic enabled::Bool
# end
# ExternalCondition() = ExternalCondition(true)
# wait(x::ExternalCondition) = isenabled(x) ? nothing : throw(KillTaskException())

struct NoCondition end
wait(::NoCondition) = nothing
const ConditionUnion = Union{Threads.Condition, Condition, NoCondition}

mutable struct Loop
    name::String
    condition::ConditionUnion
    @atomic enabled::Bool #MAYBE: redundant?
    #MAYBE: @atomic n_calls
    #MAYBE: @atomic t_last
    task::Task
    Loop(name, cond) = new(name, cond, true)
end

function show(io::IO, loop::Loop) 
    print(io, crayon"black"("LoopTask[", idstring(loop), "]"))
    print(io, " \"$(loop.name)\"")
end

function show(io::IO, ::MIME"text/plain", loop::Loop)
    print(io, loop, " - $(TaskState(loop))")
end
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop), " - ", repr(TaskState(loop)))
# Base.show(io::IO, loop::Loop) = print(io, idstring(loop), " \"$(loop.name)\"")
# Base.show(io::IO, loop::Loop) = print(io, "\"$(loop.name)\" ", idstring(loop))


iscompact(io) = get(io, :compact, false)::Bool

idstring(loop::Loop) = idstring(loop.task)
idstring(task::Task) = string(convert(UInt, pointer_from_objref(task)), base = 60)
# idstring(task::Task) = "@0x$(string(convert(UInt, pointer_from_objref(task)), base = 16, pad = Sys.WORD_SIZE>>2))"

kill(loop::Loop) = (kill!(loop); return nothing)

function kill!(loop::Loop)
    @atomic loop.enabled = false
    if !isactive(loop)
        rtk_warn("$loop is not active")
        return loop
    end
    if loop.condition isa NoCondition
        rtk_warn("$loop is waiting on an external condition to complete. ",
            "It will not be rescheduled, but will remain active until ",
            "the task encounters an error or the condition is met once again.")
            # "consider implementing a LoopCondition to automate this behavior"
    # else if loop.condition isa CustomCondition
        # kill!(loop.condition) # user defined custom behavior
    else
        rtk_info("sending stop signal to $loop")
        notify(loop)
        # notify(loop, KillTaskException(); error = true) # force waiting tasks to quit
        # could alternatively notify values to get fine grained wait behavior
    end
    yield() # let the task quit, messages print
    return loop
end

isenabled(x) = isequal(x.enabled, true)


function wait(loop::Loop)
    loop.condition isa NoCondition && return
    lock(loop.condition) do
        wait(loop.condition)
    end
end

function notify(loop::Loop, arg=nothing; kw...)
    loop.condition isa NoCondition && return
    lock(loop.condition) do
        notify(loop.condition, arg; kw...)
    end
end

## ------------------------------------ macro ------------------------------------ ##

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

macro loop(name, loop_ex)
    _loop(name, NoCondition(), :(), loop_ex, :())
end

macro loop(name, init_ex, loop_ex, final_ex)
    _loop(name, NoCondition(), init_ex, loop_ex, final_ex)
end

macro loop(name, cond, init_ex, loop_ex, final_ex)
    _loop(name, cond, init_ex, loop_ex, final_ex)
end

macro loop(name, cond, loop_ex)
    _loop(name, cond, :(), loop_ex, :())
end

function _loop(name, cond, init_ex, loop_ex, final_ex)
    quote
        local loop = Loop($name, $cond)
        loop.task = @spawn begin
            try
                rtk_info("starting $loop")
                $(esc(init_ex)) # <- user defined initializer
                wait(loop)
                while isenabled(loop)
                    $(esc(loop_ex)) # <- user defined loop
                    yield()
                    wait(loop)
                end
            catch e
                rtk_warn("$loop failed")
                rethrow(e)
            finally
                rtk_info("$loop finished")
                #TODO: unlink conditions
                $(esc(final_ex)) # <- user defined finalizer
            end
        end
        rtk_register(loop) # add to global task index
        yield() # allows the new loop task to run immediately. solid maybe
        loop # macro results in loop object
    end
end