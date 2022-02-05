
#TODO: combine freqs and daemon into timing.jl

#------------------------------------ daemon/scheduler ------------------------------------#

#FUTURE: store tasks as a sorted binary search tree (AVLTree)
# for now, use `naive` implementation from SRTxBase

# type alias
# Timer = Signal{Tuple{Hz, Nanosecond}}

mutable struct Daemon
    timers::Vector{Signal}
    lock::ReentrantLock # for timers or 
    self::Union{Reaction,Nothing} # store the daemon's task (to tell if it's running/crashed/etc.)
end

#TODO: long form, list signals
function Base.show(io::IO, ::Daemon)
    print(io, "RTk.daemon")
end

global const daemon = Daemon(Signal[], ReentrantLock(), nothing)

function loop(dmn)
    lock(dmn.lock) do
        for tx in dmn.timers
            if now() >= gettime(tx) + tx[]
                tx[] = tx[]
            end
            # ( now() >= gettime(tx) + tx[] ) && ( tx[] = tx[] )
            # if now >= interval+timestamp -> re-store interval
            # -> therefore new timestamp and notify listeners
        end
    end
    yield()
end

function stop!(dmn::Daemon)
    lock(dmn.lock)
    @atomic dmn.self.enabled = false
    unlock(dmn.lock)
end

Timer(hz::Hz) = Signal(Nanosecond(hz))

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

function add!(dmn::Daemon, tr)
    lock(dmn.lock) do
        push!(dmn.timers, tr)
        _cycle(dmn)
    end
    yield()
    return dmn
end

function rm!(dmn::Daemon, tr)
    lock(dmn.lock) do
        filter!(!isequal(tr), dmn.timers)
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
