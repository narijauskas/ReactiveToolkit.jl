
# ------------------------------------ wait/notify/kill ------------------------------------ #

# document these as default fallbacks - maybe have them print a warning if called?
function kill(::T, tk) where {T<:AbstractTrigger}
    rtk_warn("no kill method defined for type $T")
end

wait(trig::AbstractTrigger) = true
notify(trig::AbstractTrigger, arg=true; kw...) = nothing

# ------------------------------------ ExternalTrigger ------------------------------------ #

mutable struct ExternalTrigger <: AbstractTrigger
end

function kill(::ExternalTrigger, tk)
    rtk_info("$tk is waiting on an external condition to complete. ",
    "It will not be rescheduled once complete, but will remain active until ",
    "the task encounters an error or the condition is met once again.")
    # "consider implementing a LoopCondition to automate this behavior"
end

wait(trig::ExternalTrigger) = true
notify(trig::ExternalTrigger, arg=true; kw...) = nothing



# ------------------------------------ @loop macro ------------------------------------ #

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



# ------------------------------------ ConditionTrigger ------------------------------------ #

mutable struct ConditionTrigger <: AbstractTrigger
    cond::Threads.Condition
end

function kill(::ConditionTrigger, tk)
    rtk_info("$tk has been asked to stop")
    notify(tk, false) # notify task without calling user code
end

function wait(trig::ConditionTrigger)
    @lock trig.cond wait(trig.cond)
end

function notify(trig::ConditionTrigger, arg=true; kw...)
    @lock trig.cond notify(trig.cond, arg; kw...)
end


# ------------------------------------ @on macro ------------------------------------ #

macro on(args...)
    _on(args...)
end

_on(x, loop)              = _on(x, "@on $x", :(), loop, :())
_on(x, init, loop, final) = _on(x, "@on $x", init, loop, final)
_on(x, name, loop)        = _on(x, name, :(), loop, :())

function _on(x, name, init, loop, final)
    quote
        # cond = Threads.Condition()
        # link!($(esc(x)), cond) # x can be any iterable of topics
        trig = ConditionTrigger($(esc(x)).cond)
        @loop $(esc(name)) trig $(esc(init)) $(esc(loop)) $(esc(final))
    end
end


# ------------------------------------ echo ------------------------------------ #

echo(x::AbstractTopic) = @on x "echo $(x.name)" println(x.name, ": ", x[])




# ------------------------------------ TimerTrigger ------------------------------------ #

mutable struct TimerTrigger <: AbstractTrigger
    const dt::Nano
    @atomic t_next::Nano
    @atomic enabled::Bool
end

TimerTrigger(dt::Nano) = TimerTrigger(dt, now()+dt, true)


function wait(trig::TimerTrigger)
    # add isenabled(trig) to while?
    while isenabled(trig) &&  now() < trig.t_next
        flexsleep(trig.t_next - now())
    end
    @atomic trig.t_next += trig.dt
    return true
end

function kill(trig::TimerTrigger, tk::LoopTask)
    @atomic trig.enabled = false
    rtk_info("$tk has been asked to stop")
end

# notify(trig::TimerTrigger, arg=true; kw...) = nothing


#------------------------------------ @every macro ------------------------------------#
#DOC:
macro every(args...)
    _every(args...)
end

_every(dt, loop)                = _every(dt, "@every $dt", :(), loop, :())
_every(dt, init, loop, final)   = _every(dt, "@every $dt", init, loop, final)
_every(dt, name, loop)          = _every(dt, name, :(), loop, :())

function _every(dt, name, init, loop, final)
    return quote
        # waitfor = WaitForTimer(Nano($(esc(dt))))
        trig = TimerTrigger(Nano($(esc(dt))))
        @loop $(esc(name)) trig $(esc(init)) $(esc(loop)) $(esc(final))
    end
end