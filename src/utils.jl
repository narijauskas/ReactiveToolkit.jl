# global indices

# clean
# kill_all

# overview/status

# info/print server task
@topic _INFO::String = ""

info(str) = setindex!((global _INFO), str)
#TODO: start new print server if none is running


function PrintServer(io=stdout)

    @on _INFO begin
        push!(print_buffer, _INFO[])
        if t_last_print - now() >= (1/print_freq)
            t_last_print = now()
            # print one empty line to clear julia> then
            # print each line of buffer
        end
    end

end

# useful utilities that may share common names
module RTk
    
    global const INDEX = Loop[]
    global const LOCK = ReentrantLock()
        
    #TODO: fully implement this
    info(str...) = println(CR_INFO("rtk> "), str...)
    warn(str...) = println(CR_WARN("rtk:warn> "), str...)


    function register(loop)
        lock((global LOCK)) do
            push!((global INDEX), loop)
        end
        nothing
    end

    index() = return (global INDEX)
end