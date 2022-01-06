module ReactiveToolkit


greet() = print("Hello World!")


include("times.jl")
export Nanosecond, now
export ns, μs, ms, seconds
export Hz, kHz, MHz, GHz

include("signals.jl")
export Signal, on

#TODO: Timer, every, kill!


# Signals (construction, notification, value)
# Timers (construction, notification, taskdaemon)
# ReactiveTasks (id, status, stop!(id))
# graph/overview display (link implicit connections manually)


#= Issues:
    - how to handle Signals of Signals? (forbid)
    - how to schedule MIMO tasks?
    - how to handle external inputs (eg. recv(UDPSocket))
        - maybe with a trait? Reactivity? Observability? Detectable?
=#

end # module
