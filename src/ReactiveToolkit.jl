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

end # module
