
struct Nano
    ns::UInt64
    Nano(x::UInt64) = new(x)
end
Nano(x::Nano) = x
Nano(x::Number) = Nano(round(UInt64, abs(x)))
#TODO: Nano(x::DateTime) = ...
#TODO: Nano(x::Unitful.Unit) = ...

now()       = Nano(time_ns())
nanos(x)    = Nano(x)
micros(x)   = Nano(1e3x)
millis(x)   = Nano(1e6x)
seconds(x)  = Nano(1e9x)


show(io::IO, t::Nano) = print(io, "Nano $(t.ns)")
sleep(t::Nano) = sleep(t.ns/1e9)
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
