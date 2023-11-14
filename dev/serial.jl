# collect all serial monitor examples here

## -------------------------------- init/final monitor -------------------------------- ##

# a simple serial monitor
using ReactiveToolkit
using LibSerialPort

function monitor(port_name)
    sp = SerialPort(port_name)

    tk = @loop "$port_name monitor" begin
        # initializer
        open(sp)
    end begin
        # loop task
        println(stdout, readline(sp))
    end begin
        # finalizer
        isopen(sp) && close(sp)
    end
    return tk, sp
end


# to start monitoring a port
task, port = monitor("COM3")
# either can be used to stop the task and close the port
kill(task)
close(port)

# unlike something like ROS, we could literally define this monitor in the REPL, compile it, and use it all while the robot is already running

## -------------------------------- simple monitor -------------------------------- ##

function monitor(port_name)
    sp = SerialPort(port_name)

    tk = @loop "$port_name monitor" begin
        println(stdout, readline(sp))
    end
    return tk, sp
end

# if we have a serial port that's created and open, we can monitor it like so
task = @loop "$port_name monitor" begin
    println(stdout, readline(port))
end

# this task will be suspended on the call to readline until data is available on the port
# when data is available, the task is awoken, and the message is printed to the REPL

# but this requires the user to create and open the port, and we have to remember to close the port when we're done
# so let's make a function that does all that for us




## ------------------------------------ serial io ------------------------------------ ##
# bidirectional

using ReactiveToolkit
using LibSerialPort

function serial_io(name)
    sp = SerialPort(name)
    open(sp)

    @repeat "serial monitor" begin
        println(stdout, readline(sp))
    end begin
        isopen(sp) && close(sp)
    end

    console = Signal{String}("")

    @on console begin
        write(sp, console[]*"\n")
    end

    return console, sp
end

console, port = serial_io("COM6")
# serial port 
# open serial port
# repeat "serial monitor" begin
# println(readline(sp))



## ------------------------------- stissue style listener ------------------------------- ##

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