
#TODO: serial monitor
#TODO: prime finder
#TODO: stream MOCAP

@every Minute(1) begin
    println("the time is now $(Dates.now()), remember to take a break!")
end