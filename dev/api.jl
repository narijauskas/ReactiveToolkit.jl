#= Overview

A framework for reactive programming which makes use of modern features of julia, namely atomic fields and task-based concurrency.

Based on:
    * Elm
    * Functional Reactive Programming (and it's derivatives)
    * Reactive.jl
    * Observables.jl
    * practical experience


Primary functionality is achieved by creating a directed graph. Nodes are functions/tasks which may run asynchronously (and accross multiple threads). Edges are Signals - a way of sharing data safely.


Issues:
    - how to handle MIMO tasks?
        - option 1. run task on any signal update
        - option 2. run task once all signals have updated
        - option 3. restrict to SIMO tasks (do merging separately)
            something like: on(merge(s1,s2)) do
    - signals of signals
        - just don't allow these to be constructed
    - synchronization
        - is it necessary?
        - is there a way to do it beyond just a task?
    - stopping timed tasks
        - option 1. kill tasks
            task = every(.) 
            kill!(task)
        - option 2. use a timer object
            t = Timer()
            every(t, .)
            kill!(t)
=#
#------------------------------------ signals ------------------------------------#

x = Signal(1)
x = Signal{Int}(1)

x[] = 1
x[] = 1.0

y = x[]

# these should throw an error:
# (at least temporarily?)
z = Signal(x)
z = Signal(Signal(1))

# timer signal
# () -> t
# notified on interval (taskdaemon? better scheduler?)
# used as kernels for every()

# tx = Hz(10)
# notify(tx)
# kill!(tx)

#------------------------------------ tasks ------------------------------------#
# return ReactiveTask - a wrapper for the underlying task, & any signals that it listens to

#= kwargs
    - taskref?
    - task name?
    - benchmarking?
=#

on(x) do
    # on updates to signal x
    f(...)
end

every(Hz) do
    # on periodic interval
    f(...)
end

always(x) do
    # while signal is active, no rate limiter
    f(...)
end


# for debug/overview:
# stacktrace(task) or status(task)

#------------------------------------ operators ------------------------------------#
# signal -> signal (with an internal task)


# y = merge(xs...)
# y = {xs...}

# stateless maps (lift)
# y = map(f, xs...)
# y = f(xs...)
# f(xs...) -> x

# stateful map (fold previous)
# y = foldp(f, xs...)
# y = foldp(f, x)
# y = f(x, xn-1, ..., x0)

# rate limiter
# y = throttle(x, Hz)

# conditional limiters
# y = filter(f, x)
# y = {x | f(x) is true} 

# y = drop(x) # drop repeats
# y = {x | xn != xn-1}


#------------------------------------ maybe ------------------------------------#

# bind
# associate the lifetimes of signals/tasks

# flatten
# (maybe) Signal{Signal{T}} -> Signal{T}
# Array{Signal{T}} -> Signal{Array{T}}
# Signal{T} -> Signal{T} # (default)

# zip(xs)

# y = sample(Hz, x)
# ys... = sample(Hz, xs...)

# delay(f, y, xs...)
# see Reactive.jl source code
# do f(xs...) after y

# y = similar(x)

# after(f, t, xs...)
after(t) do
    # f(xs...)
end

#------------------------------------ useful stuff ------------------------------------#

# tuple of current value and last few terms
# x -> (x[n], x[n-1])

# overveiw()
# show system graph
# show active/failed nodes

#------------------------------------ other ------------------------------------#


#= every is equivalent to
- make a signal which gets updated periodically by taskdaemon
    - check all times, or sort?
- on that signal, do a thing
=#




# RepeatingTask - [active]
# repeats every: Hz

# ReactiveTask - [ready]
# reacts to: ...signals...[active]



after(sec) do
    ex 
end
#= becomes (quick and dirty)
    @async begin
        sleep(sec)
        ex
    end
=#

