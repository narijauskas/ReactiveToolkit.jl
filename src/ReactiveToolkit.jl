module ReactiveToolkit

using Crayons
# printgr(s) = print(crayon"grey", s, crayon"default")
printcr(c::Crayon, xs...) = printcr(stdout::IO, c, xs...)
printcr(io::IO, c::Crayon, xs...) = print(io, crayon"bold", c, xs..., crayon"default", crayon"!bold")

# printgr(xs...) = printgr(stdout::IO, xs...)
# printgr(xs...) = print(crayon"gray", xs..., crayon"default")


using Base.Threads: @spawn, Condition
using Sockets # maybe not

#MAYBE: import Observables for compatibility?


include("freqs.jl")
export Nanosecond, now
export ns, μs, ms, seconds
export Hz, kHz, MHz, GHz

include("signals.jl")
export Signal


include("reactions.jl")
export Reaction, @reaction
export stop!
export @on


#TODO: combine freqs and daemon into timing.jl
include("daemon.jl")
export @at


# include("tasks.jl")
# export ReactiveTask
# export on, every

#TODO: Timer, every, kill!


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
        - maybe make it a type of signal

using Sockets
sock = UDPSocket()

function on(fn, sock)
    rt = ReactiveTask()


    while isopen(sock)
        fn(recv(sock))
    end

    return rt
end

close(sock)
=#

#= performance of a captured variable in closures
    does the compiler know the return type of a signal?

    https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured
    https://github.com/c42f/FastClosures.jl
    https://github.com/JuliaLang/julia/issues/964
    https://docs.julialang.org/en/v1/manual/types/#Type-Declarations-1
=#

end # module
