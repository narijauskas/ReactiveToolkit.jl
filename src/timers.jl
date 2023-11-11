



# regular sleep, most efficient, won't be accurate below 10ms, especially on Windows
sleep(nanos::Nano) = sleep(nanos.ns/1e9)


# Linux-only micro-sleep function, best for 5ms to 500us
function microsleep(t::Nano)
    @static if Sys.islinux()
        ccall(:usleep, Cint, (Cuint,), t.ns*1000)
    else
        yieldsleep(t)
    end
end

# yielding sleep - accurate but uses more CPU resources
# should be marginally better than yield alone because it won't jump threads (as of julia v1.7)
# (not-quite busy wait, still yields to scheduler)
function yieldsleep(t::Nano)
    t0 = now()
    while now() < t0 + t
        yield()
    end
end

# busy wait/sleep - last resort, most accurate, uses a lot of CPU resources
function busywait(t::Nano)
    t0 = now()
    while now() < t0 + t
        nothing
    end
end

# choose the best sleep function for the given interval
# probably needs a bit of tuning
function flexsleep(t::Nano)
    t > millis(10) ? sleep(t - millis(1)) :
    t > micros(10) ? microsleep(t - micros(1)) :
    t > nanos(10)  ? yieldsleep(t - nanos(1)) :
    busywait(t)
end

function wait(trig::TimerTrigger)
    while now() < trig.t_next
        flexsleep(trig.t_next - now())
    end
    trig.t_next += trig.dt
    return true
end

# function wait(t::Nano)
#     t_next = now() + t

#     # while now() < t_next
#     #     if now() + millis(10) < t_next
#     #         sleep(t - millis(1))
#     #     else if now() + micros(10) < t_next
#     #         microsleep(t - micros(1))
#     #     else
#     #         yieldsleep(t)
#     #     end
#     # end
# end




#------------------------------------ at macro ------------------------------------#

macro every(args...)
    _every(args...)
end

_every(dt, loop)                = _every(dt, "@every $dt", :(), loop, :())
_every(dt, init, loop, final)   = _every(dt, "@every $dt", init, loop, final)
_every(dt, name, loop)          = _every(dt, name, :(), loop, :())

function _every(dt, name, init, loop, final)
    #augment finalizer to remove timer from daemon
    # _final = quote
    #     rm!(ReactiveToolkit.DAEMON, timer)
    #     $(esc(final))
    # end

    return quote
        # timer = Topic(Nano($dt))
        # add!(ReactiveToolkit.DAEMON, timer)
        # rtk_schedule(timer)
        trig = TimerTrigger(Nano($dt))
        @loop $(esc(name)) trig $(esc(init)) $(esc(loop)) $(esc(final))
    end
end