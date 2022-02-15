
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


Base.show(io::IO, ::TaskActive) = printcr(io, crayon"green", "[active]")
Base.show(io::IO, ::TaskFailed) = printcr(io, crayon"red", "[failed]")
Base.show(io::IO, ::TaskDone)   = printcr(io, crayon"magenta", "[done]")











## ------------------------------------ Reactions ------------------------------------ ##

mutable struct Action
    name::String
    @atomic enabled::Bool
    task::Task
    #MAYBE: trigger::Any <- would allow stopping timers, removing signal conditions
    Action(name) = new(name, true)
end


function Base.show(io::IO, axn::Action)
    print(io, "$(axn.name) - $(TaskState(axn))")
end





# is it allowed to run?
isenabled(axn) = axn.enabled
function stop!(axn::Action)
    @atomic axn.enabled = false
    return axn
end




## ------------------------------------ globals ------------------------------------ ##

global index = Action[]
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


## ------------------------------------ macro ------------------------------------ ##

macro repeat(name, ex, fx=:())
    return quote
        axn = Action($name)

        axn.task = @spawn begin
            try
                println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) starting")
                while isenabled(axn)
                    $(esc(ex)) # escape the expression
                    yield()
                end
            catch e
                rethrow(e)
            finally
                println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) stopped")
                $(esc(fx))
            end
        end

        push!(ReactiveToolkit.index, axn)
        yield()
        axn
    end
end

macro asyncrepeat(name, ex, fx=:())
    return quote
        axn = Action($name)

        axn.task = @async begin
            try
                println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) starting")
                while isenabled(axn)
                    $(esc(ex)) # escape the expression
                    yield()
                end
            catch e
                rethrow(e)
            finally
                println(stdout, "\n", crayon"cyan", "RTk> ", crayon"default", "$($name) stopped")
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



macro on(x, ex)
    name = "on $x"
    return quote
        @reaction $name begin
            wait($(esc(x)))
            $(esc(ex))
        end # no finalizer
    end
end

