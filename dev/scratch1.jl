# topics are thread-safe, reactive data containers
x = Topic{Int}(0)

# read topic value
y = sin(x[])

# store new topic value
x[] = 1

# react to changes to topic
@on x println("x is now: $(x[])")

# update topic on regular intervals
@every seconds(10) x[] += 1




## -------------------------------- graphs -------------------------------- ##

using Graphs, GLMakie, GraphMakie

g = SimpleGraph(3)
add_edge!(g, 1, 2)

fg, ax, p = graphplot(g)
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()
fg



## -------------------------------- Reactive.jl -------------------------------- ##
# og Reactive.jl signal (julia 0.6? 0.7?)
mutable struct Signal{T}
    id::Int # also its index into `nodes`, and `edges`
    value::T
    parents::Tuple
    active::Bool
    actions::Vector{Function}
    preservers::Dict
    name::String
    function Signal{T}(v, parents, pres, name) where T
        id = length(nodes) + 1
        n=new{T}(id, v, parents, false, Function[], pres, name)
        push!(nodes, WeakRef(n))
        push!(edges, Int[])
        foreach(p->push!(edges[p.id], id), parents)
        finalizer(schedule_node_cleanup, n)
        n
    end
end
# push-based
# shared central channel of updates
# signals are typed




## -------------------------------- Signals.jl -------------------------------- ##
# signals are NOT typed
# entirely pull-based?
# on update, invalidate downstreams
# recalculates on pull & validates
# reuses value while valid
# this is smart (benchmark?)
# I want to make it *task* based, fundamentally





## -------------------------------- prime finder -------------------------------- ##

using Primes
x = Topic(1)
x[] = 1
tk1 = @on x "prime checker" begin
    isprime(x[]) && println("woah! $x is prime!")
end

# with one generator
tk2 = @every millis(10) "timer 0" x[] += 1
kill(tk2)

# with many generators
tks = map(1:100) do i
    sleep(0.1)
    @every millis(10) "timer $i" x[] += 1
end
kill.(tks)

# to kill one at a time
for tk in tks
    sleep(0.05)
    kill(tk)
end





## -------------------------------- rtk monitor -------------------------------- ##
# run in a secondary terminal
INFO = ReactiveToolkit.HEARTBEAT
tk = @spawn println(recv(rtk_status()))






## -------------------------------- breaking things -------------------------------- ##

# this is fine, as it will not update the value of x while in the wait(x) call
@on x x[]+=1

# this is not fine, as it creates an infinite loop (a good way to waste 2 cpu cores)
@on x y[]+=1
@on y x[]+=1
# the loop may break itself if both update the value at the same time, but is generally a good way to waste 2 cpu cores





## -------------------------------- UDP experiments -------------------------------- ##
using ReactiveToolkit, Sockets
using Base.Threads: @spawn
rtk_init()

x = UDPTopic{Bool}("x", 5410, false)
led = UDPTopic{UInt8}("led_knob", 5412, 0)


tk = @on led begin
    println(led[] > 200 ?
    crayon"red"("DANGER! So bright!") :
    "led = $(led[])")
end

kill(tk)





## -------------------------------- overview -------------------------------- ##
using ReactiveToolkit
# x = Topic(0)
@topic x::Int = 0

x[] == 0
typeof(x) == Topic{Int}
x[] = 1
x[] == 1

@on x "x monitor" println("x is now $(x[])")
x[] = 2







## -------------------------------- JuliaCon demo -------------------------------- ##

using ReactiveToolkit
using LibSerialPort
using Unitful

x = Topic(1.0u"ms")
y = Topic{Int}(1)


port = SerialPort("COM5")
open(port)

tk1 = @on x y[] = round(Int, x[] |> u"μs" |> ustrip)

tk2 = @on y write(port, string(y[])*"\n")

tk3 = @at Hz(10) begin
    x[] = 200u"ms" + 150*sin(2*now().ns/1e9)u"ms"
    println("x = $(x[])")
end

kill!(tk1)
kill!(tk2)
kill!(tk3)
close(port)
x[] = 200u"ms"

tk4 = @at Hz(10) begin
    led[] = sign(2*now().ns/1e9)
    println("led = $(led[])")
end

# monitor
port = SerialPort("COM5")
open(port)
tk = @loop "serial monitor" begin
    isopen(port) || @error "port closed"
    println(readline(port))
end

write(port, "SET led:state 100");

for k in 0:0.005:3
    x = round(UInt8, 127*(sin(100*k)+1))
    write(port, "SET led:state $x")
    sleep(0.005)
end
write(port, "SET led:state 0");
close(port)


[1,2,3] .|> x->"$x,"

csv(vec) = mapreduce(x->"$x,", *, vec)
csv([1,2,3,4,5])
[repeat([x],3) for x in 1:3]