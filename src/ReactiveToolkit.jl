module ReactiveToolkit

greet() = print("Hello World!")


include("times.jl")
export Nano, now
export ns, μs, ms, seconds
export Hz, kHz, MHz, GHz

include("signals.jl")
export Signal

end # module
