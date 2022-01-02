module ReactiveToolkit


greet() = print("Hello World!")


include("times.jl")
export Nanosecond, now
export ns, μs, ms, seconds
export Hz, kHz, MHz, GHz

include("signals.jl")
export Signal, on

#TODO: Timer, every, kill!


end # module
