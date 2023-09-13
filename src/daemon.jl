
#TODO: combine freqs and daemon into timing.jl

#------------------------------------ daemon/scheduler ------------------------------------#
using DataStructures


#FUTURE: store tasks as a sorted binary search tree (AVLTree)
# for now, use `naive` implementation from SRTxBase

# type alias
# Timer = Topic{Tuple{Hz, Nano}}

mutable struct Daemon
    # timers::Vector{Topic}
    # @atomic enabled::Bool
    timers::PriorityQueue{Topic{Nano}, Nano}
    lock::ReentrantLock # for timers or 
    self::Union{Loop,Nothing} # store the daemon's task (to tell if it's running/crashed/etc.)
end

#TODO: long form, list signals
function Base.show(io::IO, ::Daemon)
    print(io, "RTk.daemon")
end

global const DAEMON = Daemon(PriorityQueue{Topic{Nano}, Nano}(), ReentrantLock(), nothing)

function loop_daemon(dmn)
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

        # 1. peek
        # 2. wait best guess
        # 3. while t_remain > t_th -> sleep
        # 4. while ... -> microsleep
        # 5. while ... -> nanosleep
        # 6. notify task
        # 7. yield() -> (this should jump threads?)
        
        #FIX: what happens if dmn.timers is empty?
        if isempty(dmn.timers)
            @atomic dmn.self.enabled = false
            return
        end

        (x, t_next) = peek(dmn.timers)
        if now() >= t_next
            dmn.timers[x] = now() + x[]
            notify(x)
        elseif  now() + millis(10) < t_next
            sleep(t_next-(now()+millis(1)))
            #elseif
            #YO: make OS-specific timer kernels: like microsleep on linux, 20ms tolerance on Windows
            #microsleep()
        #elseif
            #nanosleep()
        else
            yield()
        end

    end
    # yield()
    # sleep(0.001) # temporary solution
end

#TODO:
struct Y2KException <: Exception end # -> wait for now() to wrap


#---------------------- other sleep functions ----------------------#

# Base.sleep(ns::Nanos) = sleep(ns.ns/1e9)

#TODO: update for Nanos

# Linux-only usleep function, best for 5ms to 500us
# function microsleep(usecs)
#     @static if Sys.islinux()
#         ccall(:usleep, Cint, (Cuint,), usecs)
#     else
#         nsleep(usecs*1000)
#     end
# end

# yielding sleep - accurate but uses more CPU resources
# should be better than just yield because it won't jump threads
# (not-quite busy wait, still yields to scheduler)
# function nanosleep(nsecs)
#     t0 = time_ns()
#     while time_ns() < t0 + nsecs
#         yield()
#     end
# end



function stop!(dmn::Daemon)
    lock(dmn.lock)
    @atomic dmn.self.enabled = false
    unlock(dmn.lock)
end

# Timer(hz::Hz) = Topic(Nanos(hz))

function cycle(dmn::Daemon)
    lock(dmn.lock) do
        _cycle(dmn)
    end
end

#assume lock is already held
function _cycle(dmn::Daemon)
    if isempty(dmn.timers)
        @atomic dmn.self.enabled = false
    elseif isnothing(dmn.self) || !isactive(dmn.self)
        # start daemon
        # dmn.self = @asyncloop "daemon" loop(dmn)
        # dmn.self.task.sticky = false
        dmn.self = @loop "daemon" loop_daemon(dmn)
    else
        nothing
    end
    return nothing
end

function add!(dmn::Daemon, timer)
    lock(dmn.lock) do
        enqueue!(dmn.timers, timer, timer[]+now())
        _cycle(dmn)
    end
    yield()
    return dmn
end


function rm!(dmn::Daemon, timer)
    lock(dmn.lock) do
        delete!(dmn.timers, timer)
        _cycle(dmn)
    end
    yield()
    return dmn
end

#stop!.(RTk.list) should rm all

#------------------------------------ at macro ------------------------------------#

macro every(args...)
    _every(args...)
end

_every(dt, loop)                = _every(dt, "@every $dt", :(), loop, :())
_every(dt, init, loop, final)   = _every(dt, "@every $dt", init, loop, final)
_every(dt, name, loop)          = _every(dt, name, :(), loop, :())

function _every(dt, name, init, loop, final)
    #augment finalizer to remove timer from daemon
    _final = quote
        rm!(ReactiveToolkit.DAEMON, timer)
        $(esc(final))
    end

    return quote
        timer = Topic(Nano($dt))
        add!(ReactiveToolkit.DAEMON, timer)
        # rtk_schedule(timer)
        @on timer $(esc(name)) $(esc(init)) $(esc(loop)) $_final
    end
end


# macro at(hz, ex) :() end
# macro at(hz, name, ex) :() end
# macro at(hz, init, loop, final) :() end
# macro at(hz, name, init, loop, final)
#     return quote
#         timer = Topic(Nanos($hz))
#         rtk_add(timer)
#         @loop $name $(esc(ex)) rtk_rm(timer)
#         @on timer $name $(esc(ex))
#     end
# end

# macro at(hz, ex)
#     name = "at $hz"
#     return quote
#         ns = Nanos($hz)
#         # make timer -> attatch to taskdaemon (lock, start/stop)
#         timer = Topic(ns)
#         add!(ReactiveToolkit.daemon, timer)

#         @loop $name begin
#             wait(timer)
#             $(esc(ex))
#         end begin
#             # finalizer -> remove from taskdaemon (lock, start/stop)
#             rm!(ReactiveToolkit.daemon, timer)
#         end
#     end
# end
