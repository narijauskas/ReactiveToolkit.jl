
struct Nano
    ns::UInt64
    Nano(x::UInt64) = new(x)
end
Nano(x::Nano) = x
Nano(x::Number) = Nano(round(UInt64, abs(x)))
Nano(x::Dates.Nanosecond) = Nano(x.value)
Nano(x::Dates.AbstractTime) = Nano(Nanosecond(x))
#TODO: Nano(x::Unitful.Unit) = ...

now()       = Nano(time_ns())
nanos(x)    = Nano(x)
micros(x)   = Nano(1e3x)
millis(x)   = Nano(1e6x)
seconds(x)  = Nano(1e9x)


show(io::IO, t::Nano) = print(io, "Nano $(t.ns)")
# sleep(t::Nano) = sleep(t.ns/1e9)
#MAYBE: since(t::Nano) = now() - t
#MAYBE: until(t::Nano) = t - now()
#MAYBE: freq(t::Nano) = (1e9/t.ns)u"Hz"

#------------------- operators -------------------#
isless(t1::Nano, t2::Nano) = isless(t1.ns, t2.ns)
+(t1::Nano, t2::Nano) = Nano(t1.ns + t2.ns)
-(t1::Nano, t2::Nano) = Nano(t1 > t2 ? t1.ns - t2.ns : t2.ns - t1.ns)
*(t::Nano, k::Number) = Nano(t.ns*k)
*(k::Number, t::Nano) = Nano(k*t.ns)
/(t1::Nano, t2::Nano) = t1.ns/t2.ns
/(t::Nano, k::Number) = Nano(t.ns/k)

Dates.Nanosecond(t::Nano) = Nanosecond(t.ns)
ago(t::Nano) = "$(Nanosecond(now()-t) |> canonicalize |> t->first(t.periods)) ago"
# function since(t::Nano)
#     dt = now() - t
#     # 
    
#     dt >= 1.0u"hr"
#     dt >= 1.0u"min"
#     dt <= 1.0u"μs"
# end




#------------------------------------ sleep functions ------------------------------------#


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

#TODO: implement or remove. time_ns() shouldn't wrap for some 500 years
struct Y2KException <: Exception end


