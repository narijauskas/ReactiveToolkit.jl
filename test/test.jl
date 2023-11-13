using ReactiveToolkit


# x = Topic(0)
@topic x::Int = 0

x[] == 0
typeof(x) == Topic{Int}
x[] = 1
x[] == 1

@on x "x monitor" println("x is now $(x[])")
x[] = 2





# @topic x::Int # should throw error


















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

# tk = @every seconds(1) println("hello")


# tk = @on x println("x is now: $(x[])")
# # @topic 5410 x::Int = 0

# open(rtk_status())
# send(rtk_status(), "hello world")

# # using MacroTools
# # using Unitful

# @topic 5310 x::Int = 0
# x = Topic{Int}(5310, 0)
# x = @topic 5310 String

# tk = @loop "startup" sleep(1)
# kill(tk)
# x = Topic()
# y = Topic()
# tk = @on [x,y] rtk_print(y[])



# t = LinRange(0,1,100)
# xs = @. 127*(sin(2π*t)+1)
# xxs = repeat(round.(UInt8,xs),10)
# tk = @every millis(10) y[] = pop!(xxs)

# y[] = 3
# x[] = 1

# kill(tk)



#TODO: speed test
# task holds a topic{Dict}


@every seconds(0.5) yeet()
kill(ans)


t = UDPTopic("t", 5413, now())


kill.(rtk_index())


using Primes
x = Topic(1)
x[] = 1
tk = @on x "prime check" begin
    isprime(x[]) && println("woah! $x is prime!")
end
tk = @every millis(10) "timer 0" x[] += 1
kill(tk)


tks = map(1:100) do i
    sleep(0.1)
    @every millis(10) "timer $i" x[] += 1
end

kill.(tks)

for tk in tks
    sleep(0.05)
    kill(tk)
end

INFO = ReactiveToolkit.HEARTBEAT

😃
tk = @spawn println(recv(rtk_status()))

# this is fine, as it will not update the value of x while in the wait(x) call
@on x x[]+=1

# this is not fine, as it creates an infinite loop (a good way to waste 2 cpu cores)
@on x y[]+=1
@on y x[]+=1
# the loop may break itself if both update the value at the same time, but is generally a good way to waste 2 cpu cores