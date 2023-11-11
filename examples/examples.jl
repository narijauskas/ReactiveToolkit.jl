
#TODO: serial monitor
#TODO: prime finder
#TODO: stream MOCAP


# a simple serial monitor
using ReactiveToolkit
using LibSerialPort

function monitor(port_name)
    sp = SerialPort(port_name)

    tk = @loop "$port_name monitor" begin
        open(sp)
    end begin
        println(stdout, readline(sp))
    end begin
        isopen(sp) && close(sp)
    end
    return tk, sp
end

# task, port = monitor("dev/ttyUSB0")

# to start monitoring a port
task, port = monitor("COM3")
# either can be used to stop the task and close the port
kill(task)
close(port)

# unlike something like ROS, we could literally define this monitor in the REPL, compile it, and use it all while the robot is already running


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