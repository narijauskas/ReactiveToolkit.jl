
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

mutable struct Reaction
    name::String
    enabled::Bool
    task::Task
    Reaction(name) = new(name, true)
end


function Base.show(io::IO, rxn::Reaction)
    print(io, "Reaction - $(TaskState(rxn))")
end





# is it allowed to run?
isenabled(rxn) = rxn.enabled
disable!(rxn) = setproperty!(rxn, :enabled, false), return rxn
stop!(rxn) = disable!(rxn)




## ------------------------------------ globals ------------------------------------ ##

global index = Reaction[]
# list()
# index
# index by index or name

# purge!()




## ------------------------------------ marcro ------------------------------------ ##


#TODO: test this
# macro reaction(ex)
#     @reaction "Reaction" ex
# end

macro reaction(name, ex)
    return quote
        rxn = Reaction($name)

        rxn.task = @spawn begin
            try
                @info "starting $($name)"
                while isenabled(rxn)
                    $(esc(ex)) # escape the expression
                    yield()
                end
            catch e
                if e isa TaskDone
                    println("done!")
                else
                    rethrow(e)
                end
                # e isa TaskDone && rethrow(e)
            finally
                @info "$($name) stopped"
            end
        end

        #TODO: index register rxn
        push!(ReactiveToolkit.index, rxn)

        rxn
    end
end




## ------------------------------------ on/every ------------------------------------ ##

# onany(f, xs...)
# make a signal that waits for any, then notifies common?


function on(f, x)
    # make condition
    # add condition to each x in xs...
    @reaction "ON" begin
        wait(cond)
        f()
    end
end



function every(f, x)
    # make timer
    # add condition to taskdaemon
    @reaction "EVERY" begin
        wait(cond)
        f()
    end
end
