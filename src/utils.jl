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
            # print each line of buffer
        end
    end

end

