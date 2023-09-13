# Observable are thread-safe, reactive data containers
x::Observable{Int} = Observable(0)

# read topic value
y = sin(x[])

# store new topic value
x[] = 1

# react to changes to topic
@on x begin
    println("x is now: $(x[])")
end

# update topic on regular intervals
@every seconds(10) x[] += 1






using LibSerialPort
using RealtimeToolkit

# very crude microcontroller IO
x::Observable{UInt16} = Observable(0)
x::Observable{UInt16} = Observable(0)


serial = SerialPort("COM4")
open(serial)

@loop begin
    isopen(serial) && error("serial port closed")
    x[] = parse(UInt16, readline(serial))
end begin #finalizer
    isopen(serial) && close(serial)
end

@on u write(serial, "SET CH1.U $(u[])")


let K = 1
    @on x u[] = K*x[]
end



function MCUListener(port, mcuin, mcuout)
    mcu_port = SerialPort(port)
    open(mcu_port)

    mcu_listener = @loop begin
        isopen(mcu_port) && error("serial port closed")
        mcuout[] = parse(UInt16, readline(mcu_port))
    end begin #finalizer
        isopen(mcu_port) && close(mcu_port)
    end

    mcu_writer = @on mcuin write(mcu_port, "SET CH1.U $(mcuin[])")
    return mcu_listener, mcu_writer, mcu_port
end


ports = ["COM1", "COM2", "COM3"]
inputs = [Observable{UInt16}(0), Observable{UInt16}(0), Observable{UInt16}(0)]
outputs = [Observable{UInt16}(0), Observable{UInt16}(0), Observable{UInt16}(0)]
for (port, input, output) in zip(ports, inputs, outputs)
    MCUListener(port, input, output)
end

@onany inputs begin
    x = collect(input[] for input in inputs)
    us = K*x
    for (output, u) in zip(outputs, us)
        output[] = u
    end
end








# useful for things like control loops

@on mcu begin
    x[] = parse(Float64, readline(serial))
end

@on x u[] = K*x[]

@on u write(serial, "SET CH1.U $(u[])")



@on (a,b,c) begin
    println("either a,b, or c has been updated")
end

@onall (a,b,c) begin
    println("a,b, and c have all been updated at least once")
end



function PrintServer(;repl_rate=Hz(60))
    print_buffer = Signal{CircularBuffer{String}}()
end

rtk_println() #
rtk_print()