
@on (a,b,c) begin
    println("either a,b, or c has been updated")
end

@onall (a,b,c) begin
    println("a,b, and c have all been updated at least once")
end

# alternatively:
@on all((a,b,c)) do_stuff()
@on any((a,b,c)) do_stuff()

# or even:
abc = all((a,b,c)) # returns a compound topic/condition?
# abc = flatten([a,b,c])
@on abc do_stuff()

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
        - option 3. use a global task list
            every(Hz) do ...
            kill!(RTk.overview()[1])
    - stopping regular tasks
        1. stop signal task is based on
        2. kill task itself (via handle)
        3. have global list of tasks (probably useful)
            RTk.overview()
    
    RTk.graph()
        - global overview


Task Control:
    tasks are assigned a unique taskid on creation
    stored to global registry
    display as graph
    know input signal (signals?)
    how to represent outputs for arbitrary on fxns?
    stop!(taskid)

    tasks have a status: runnable(active)/failed/done
    tasks have an id: stop!(taskid)
=#


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
