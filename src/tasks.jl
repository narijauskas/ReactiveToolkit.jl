
mutable struct ReactiveTask
    enabled::Bool
    trigger::AbstractSignal # or condition from signal?
    task::Task
    # name::Union{String,Nothing}
    #...?
    ReactiveTask(x) = new(true, x) # assign task later
end

isenabled(rt::ReactiveTask) = rt.enabled

#TODO:
# status(rt) - active/failed/done

# TODO: show()

function on(f, x)
    rt = ReactiveTask(x)
    # create ReactiveTask
    # assign taskid
    # register globally

    @spawn try
        @info "starting"
        while isenabled(rt)
            wait(rt)
            f()
        end
    finally
        @info "stopped"
    end

    ...
    return rt
end

#TODO:
# destroy!(taskid)
# deregister globally

function stop!(rt::ReactiveTask)
    rt.enabled = false
    notify(rt.trigger)
end

#TODO:
# stop!(taskid)
# lookup & stop

function every(f, freq)
    ...
    return rt
end



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