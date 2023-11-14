



function kill(::ConditionTrigger, tk)
    rtk_info("$tk has been asked to stop")
    notify(tk, false) # notify task without calling user code
end

wait(trig::ConditionTrigger) = @lock trig.cond wait(trig.cond)
notify(trig::ConditionTrigger, arg=true; kw...) = @lock trig.cond notify(trig.cond, arg; kw...)


function kill(::ExternalTrigger, tk)
    rtk_info("$tk is waiting on an external condition to complete. ",
    "It will not be rescheduled once complete, but will remain active until ",
    "the task encounters an error or the condition is met once again.")
    # "consider implementing a LoopCondition to automate this behavior"
end

wait(trig::ExternalTrigger) = true
notify(trig::ExternalTrigger, arg=true; kw...) = nothing

# function kill(tk::LoopTask)
#     @atomic tk.enabled = false
#     if !isactive(tk)
#         rtk_warn("$tk is not active")
#     elseif tk.trigger isa ExternalTrigger
#         rtk_warn("$tk is waiting on an external condition to complete. ",
#             "It will not be rescheduled, but will remain active until ",
#             "the task encounters an error or the condition is met once again.")
#             # "consider implementing a LoopCondition to automate this behavior"
#     # elseif tk.condition isa CustomCondition
#         # kill!(tk.condition) # user defined custom behavior
#     else
#         rtk_info("$tk has been asked to stop")
#         notify(tk, false) # notify task without calling user code
#     end
#     yield() # maybe. let the task quit, messages print
#     nothing
# end

# document these as default fallbacks - maybe have them print a warning if called?
wait(trig::AbstractTrigger) = true
notify(trig::AbstractTrigger, arg=true; kw...) = nothing
function kill(::T, tk) where {T<:AbstractTrigger}
    rtk_warn("no kill method defined for type $T")
end

# wait(trig::TimerTrigger) = sleep(0.001) #TODO: make this a bit more intelligent
# notify(trig::TimerTrigger, arg=true; kw...) = nothing




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
                $(esc(final_ex)) # <- user defined finalizer
            end
        end
        rtk_register(tk) # add to global task index
        yield() # allows the new loop task to run immediately. solid maybe
        tk # macro results in LoopTask object
    end
end
