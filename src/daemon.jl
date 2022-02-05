
#TODO: combine freqs and daemon into timing.jl

#------------------------------------ daemon/scheduler ------------------------------------#
using DataStructures

# # peek(pq)[2] -> t_next
# (timer, t_next) = peek(pq)
# if now() >= t_next
#     pq[timer] = now() + timer[]
#     notify(timer)
# end

# elseif  now() >= t_next + ms(2)
#     sleep(t_next-(now()+ms(1)))
# end

# peek(pq)[1] -> timer
Base.sleep(ns::Nanosecond) = sleep(ns.ns/1e9)

#FUTURE: store tasks as a sorted binary search tree (AVLTree)
# for now, use `naive` implementation from SRTxBase

# type alias
# Timer = Signal{Tuple{Hz, Nanosecond}}

mutable struct Daemon
    # timers::Vector{Signal}
    timers::PriorityQueue{Signal{Nanosecond}, Nanosecond}
    lock::ReentrantLock # for timers or 
    self::Union{Reaction,Nothing} # store the daemon's task (to tell if it's running/crashed/etc.)
end

#TODO: long form, list signals
function Base.show(io::IO, ::Daemon)
    print(io, "RTk.daemon")
end

global const daemon = Daemon(PriorityQueue{Signal{Nanosecond}, Nanosecond}(), ReentrantLock(), nothing)

function loop(dmn)
    lock(dmn.lock) do
        #=
        for timer in dmn.timers
            if now() >= gettime(timer) + timer[]
                timer[] = timer[]
            end
            # ( now() >= gettime(tx) + tx[] ) && ( tx[] = tx[] )
            # if now >= interval+timestamp -> re-store interval
            # -> therefore new timestamp and notify listeners
        end
        =#
        
        #YO:
        (timer, t_next) = peek(dmn.timers)
        if now() >= t_next
            dmn.timers[timer] = now() + timer[]
            notify(timer)
        elseif  now() + ms(2) < t_next
            sleep(t_next-(now()+ms(1)))
        else
            yield()
        end

    end
    # yield()
    # sleep(0.001) # temporary solution
end

#TODO:
#err: Y2KException() -> wait for now() to wrap

function stop!(dmn::Daemon)
    lock(dmn.lock)
    @atomic dmn.self.enabled = false
    unlock(dmn.lock)
end

# Timer(hz::Hz) = Signal(Nanosecond(hz))

#assume lock is already held
function _cycle(dmn::Daemon)
    if isempty(dmn.timers)
        @atomic dmn.self.enabled = false
    elseif isnothing(dmn.self) || TaskActive() != TaskState(dmn.self)
        # start daemon
        dmn.self = @reaction "daemon" loop(dmn)
    else
        nothing
    end
    return nothing
end

function add!(dmn::Daemon, timer)
    lock(dmn.lock) do
        # push!(dmn.timers, timer)
        enqueue!(dmn.timers, timer, timer[]+now())
        _cycle(dmn)
    end
    yield()
    return dmn
end

function rm!(dmn::Daemon, timer)
    lock(dmn.lock) do
        # filter!(!isequal(timer), dmn.timers)
        delete!(dmn.timers, timer)
        _cycle(dmn)
    end
    yield()
    return dmn
end

#stop!.(RTk.list) should rm all

#------------------------------------ at macro ------------------------------------#
# managed by daemon

macro at(hz, ex)
    name = "at $hz"
    return quote
        ns = Nanosecond($hz)
        # make timer -> attatch to taskdaemon (lock, start/stop)
        timer = Signal(ns)
        add!(ReactiveToolkit.daemon, timer)

        @reaction $name begin
            wait(timer)
            $(esc(ex))
        end begin
            # finalizer -> remove from taskdaemon (lock, start/stop)
            rm!(ReactiveToolkit.daemon, timer)
        end
    end
end

# # @at hz ex
# @at hz "name" ex

# function every(f, x)
#     # make timer
#     # add condition to taskdaemon
#     @reaction "EVERY" begin 
#         wait(cond)
#         f()
#     end
# end
