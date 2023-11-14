

function wait(trig::TimerTrigger)
    # add isenabled(trig) to while?
    while now() < trig.t_next
        flexsleep(trig.t_next - now())
    end
    trig.t_next += trig.dt
    return true
end

#FIX: kill(::TimerTrigger, tk::LoopTask) = nothing #TODO: kill timer


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