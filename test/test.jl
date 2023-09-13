using ReactiveToolkit
using MacroTools
using Unitful
tk = @loop "startup" sleep(1)
x = Topic()
y = Topic()
tk = @on [x,y] println(y[])


# y[] = 3
x[] = 1

kill(tk)



@every seconds(0.5) println("hello")
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