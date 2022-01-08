module ReactiveToolkit

using Base.Threads: @spawn, Condition

#MAYBE: import Observables for compatibility?

greet() = print("Hello World!")


include("freqs.jl")
export Nanosecond, now
export ns, μs, ms, seconds
export Hz, kHz, MHz, GHz

include("signals.jl")
export Signal

#TODO: Timer, every, kill!


include("tasks.jl")
export on, every

# Signals (construction, notification, value)
# Timers (construction, notification, taskdaemon)
# ReactiveTasks (id, status, stop!(id))
# graph/overview display (link implicit connections manually)


#= Issues:
    - how to handle Signals of Signals? (forbid)
    - how to schedule MIMO tasks?
        - onany by default
        - how to notify only when all?
    - how to handle external inputs (eg. recv(UDPSocket))
        - maybe with a trait? Reactivity? Observability? Detectable?
=#

#= performance of a captured variable in closures
    does the compiler know the return type of a signal?

    https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured
    https://github.com/c42f/FastClosures.jl
    https://github.com/JuliaLang/julia/issues/964
    https://docs.julialang.org/en/v1/manual/types/#Type-Declarations-1
=#

end # module
