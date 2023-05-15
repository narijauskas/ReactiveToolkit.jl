# Signals
# thread-safe, reactive data containers

x::Signal{Int} = Signal(0)

# read signal value
x[]

# store new signal value
x[] = 1

# react to changes to x
@on x println("x is now: $(x[])")

# do things on regular intervals
@every seconds(10) x[] += 1



# useful for things like control loops

@on mcu begin
    x[] = parse(Float64, readline(serial))
end

@on x u[] = K*x[]

@on u write(serial, "SET CH1.U $(u[])")

@always begin
    isopen(serial) && error("serial port closed")
    x[] = parse(UInt16, readline(serial))
end

@onany (a,b,c) begin
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