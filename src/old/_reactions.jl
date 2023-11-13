
## ------------------------------------ task state ------------------------------------ ##

# abstract type TaskState end

# # there is no task
# struct NoTask <: TaskState end

# # task is currently runnable
# struct TaskActive <: TaskState end

# # task has crashed - see x.task for details
# struct TaskFailed <: TaskState end

# # task has completed - most likely stopped manually via kill!(x)
# struct TaskDone <: TaskState end

# TaskState(::Nothing) = NoTask()

# function TaskState(x)
#     if istaskfailed(x.task)
#         return TaskFailed()
#     elseif istaskdone(x.task)
#         return TaskDone()
#     else
#         return TaskActive()
#     end
# end


# Base.show(io::IO, ::NoTask) = printcr(io, crayon"dark_gray", "[no task]")
# Base.show(io::IO, ::TaskActive) = printcr(io, crayon"green", "[active]")
# Base.show(io::IO, ::TaskFailed) = printcr(io, crayon"red", "[failed]")
# Base.show(io::IO, ::TaskDone)   = printcr(io, crayon"magenta", "[done]")











## ------------------------------------ Reactions ------------------------------------ ##

mutable struct Reaction
    name::String
    @atomic enabled::Bool
    task::Task
    #MAYBE: trigger::Any <- eg. Condition. Would allow stopping timers, removing signal conditions, interupting wait?
    Reaction(name) = new(name, true)
end


function Base.show(io::IO, axn::Reaction)
    print(io, "$(axn.name) - $(TaskState(axn))")
end





# is it allowed to run?
isenabled(axn) = axn.enabled
function kill!(axn::Reaction)
    @atomic axn.enabled = false
    # @async Base.throwto(axn.task, InterruptException())
    # some kind of yieldto?
    return axn
end




## ------------------------------------ globals ------------------------------------ ##

global index = Reaction[]
#TODO: const
#TODO: direct getters/setters

# list()
# index
# index by index or name

#TODO: return list
#TODO: list type

#DOC: list reactions in the global index (ie. those created by @reaction)
function list()
    global index
    foreach(enumerate(index)) do (i, axn)
        println("[$i] - $axn")
    end
    return nothing
end

#DOC: remove inactive reactions from the index
function clean!()
    global index
    filter!(index) do axn
        TaskState(axn) == TaskActive()
    end
    return nothing
end



# graph!(ax)
# info(msg) = println(stdout, "\n", crayon"magenta", crayon"bold", "RTk> ", crayon"default", crayon"!bold", msg)

## ------------------------------------ macro ------------------------------------ ##

# macro loop(name, ex, fx=:())
#     return quote
#         axn = Reaction($name)

#         axn.task = @spawn begin
#             try
#                 # println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) starting")
#                 info("$($name) starting")
#                 while isenabled(axn)
#                     $(esc(ex)) # escape the expression
#                     yield()
#                 end
#             catch e
#                 rethrow(e)
#             finally
#                 # println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) stopped")
#                 info("$($name) stopped")
#                 $(esc(fx))
#             end
#         end

#         push!(ReactiveToolkit.index, axn)
#         yield()
#         axn
#     end
# end

#FUTURE: replace @spawn with @async based on kwarg
macro asyncloop(name, ex, fx=:())
    return quote
        axn = Reaction($name)

        axn.task = @async begin
            try
                println(stdout, "\n", crayon"magenta", crayon"bold", "RTk> ", crayon"default", "$($name) starting")
                while isenabled(axn)
                    $(esc(ex)) # escape the expression
                    yield()
                end
            catch e
                rethrow(e)
            finally
                println(stdout, "\n", crayon"magenta", crayon"bold", "RTk> ", crayon"default", "$($name) stopped")
                $(esc(fx))
            end
        end

        push!(ReactiveToolkit.index, axn)
        yield() # set sticky before this?
        axn
    end
end



## ------------------------------------ on/every ------------------------------------ ##

# onany(f, xs...)
# make a signal that waits for any, then notifies common?

# @on x ex
# @on x "name" ex

# macro on(x, ex)
#     name = "@on $x"
#     @on(x, name, ex)
# end

# macro on(x, name, ex)
#     return quote
#         @loop $name begin
#             wait($(esc(x)))
#             $(esc(ex))
#         end # no finalizer
#     end
# end

# macro on(x, name, ex)
#     @loop $name cond () $(esc(ex)) ()
# end

# macro on(x, ex)
#     name = "@on $x"
#     return quote
#         @loop $name begin
#             wait($(esc(x)))
#             $(esc(ex))
#         end # no finalizer
#     end
# end



