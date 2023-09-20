using ReactiveToolkit, Sockets
using Base.Threads: @spawn
rtk_init()

x = UDPTopic{Int}("x", 5410, 0)
tk = @on x println("x is now: $(x[])")
# @topic 5410 x::Int = 0

open(rtk_status())
send(rtk_status(), "hello world")

# using MacroTools
# using Unitful

@topic 5310 x::Int = 0
x = Topic{Int}(5310, 0)
x = @topic 5310 String

tk = @loop "startup" sleep(1)
kill(tk)
x = Topic()
y = Topic()
tk = @on [x,y] rtk_print(y[])


y[] = 3
x[] = 1

kill(tk)

#TODO: speed test
# task holds a topic{Dict}


@every seconds(0.5) yeet()
kill(ans)



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


tk = @spawn println(recv(rtk_status()))
