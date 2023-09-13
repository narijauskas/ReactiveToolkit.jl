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