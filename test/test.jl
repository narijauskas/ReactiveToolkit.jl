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



@every seconds(1) println("hello")
kill(ans)







x = Topic(1)
x[] = 1
@on x "prime check" begin
    isprime(x[]) && println("woah! $x is prime!")
end
@every millis(10) x[] += 1
kill(ans)