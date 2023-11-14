global const TASK_INDEX = ReactiveTask[]
global const TASK_LOCK = ReentrantLock()
global PRINT_TO_REPL::Bool = true
# global const STATUS = UDPMulticast(ip"230.8.6.7", 5309)


CR_GRAY = crayon"dark_gray"
CR_BOLD = crayon"bold"
CR_EMPH = crayon"italics"
CR_INFO = crayon"bold"*crayon"magenta"
CR_WARN = crayon"bold"*crayon"yellow"
CR_ERR  = crayon"bold"*crayon"red"


function rtk_print(str...)
    PRINT_TO_REPL && println(repeat([""], 32)..., "\r", str...)
    # isopen(STATUS) && send(STATUS, string(str...))
end


rtk_info(str...) = rtk_print(CR_INFO("rtk> "),       str...)
rtk_warn(str...) = rtk_print(CR_INFO("rtk:warn> "),  str...)
rtk_err(str...)  = rtk_print(CR_INFO("rtk:error> "), str...)


function rtk_register(tk::ReactiveTask)
    @lock TASK_LOCK push!(TASK_INDEX, tk)
    return nothing
end

rtk_tasks() = @lock TASK_LOCK return TASK_INDEX
rtk_count() = @lock TASK_LOCK sum(isactive.(TASK_INDEX))
rtk_clean() = @lock TASK_LOCK filter!(isactive, TASK_INDEX)
# rtk_status() = return STATUS
# rtk_topics()
rtk_kill_all() = @lock TASK_LOCK foreach(kill, TASK_INDEX)

# function rtk_init(; print_to_repl = true)
#     global PRINT_TO_REPL = print_to_repl
#     global STATUS
#     open(STATUS)
#     rtk_info("Starting ReactiveToolkit.jl")
#     # ip address
#     # number of threads
#     # hostname
#     # julia version
#     # OS
#     # processID
#     isopen(STATUS)
# end




# #DOC: list reactions in the global index (ie. those created by @reaction)
# function list()
#     global index
#     foreach(enumerate(index)) do (i, axn)
#         println("[$i] - $axn")
#     end
#     return nothing
# end

# #DOC: remove inactive reactions from the index
# function clean!()
#     global index
#     filter!(index) do axn
#         TaskState(axn) == TaskActive()
#     end
#     return nothing
# end





# function PrintServer(;repl_rate=Hz(60))
#     print_buffer = Signal{CircularBuffer{String}}()
# end


# global indices

# clean
# kill_all

# overview/status

# # info/print server task
# @topic _INFO::String = ""

# info(str) = setindex!((global _INFO), str)
# #TODO: start new print server if none is running


# function PrintServer(io=stdout)

#     @on _INFO begin
#         push!(print_buffer, _INFO[])
#         if t_last_print - now() >= (1/print_freq)
#             t_last_print = now()
#             # print one empty line to clear julia> then
#             # print each line of buffer
#         end
#     end

# end

# # useful utilities that may share common names
# module RTk
    
#     global const INDEX = Loop[]
#     global const LOCK = ReentrantLock()
        
#     #TODO: fully implement this
#     info(str...) = println(CR_INFO("rtk> "), str...)
#     warn(str...) = println(CR_WARN("rtk:warn> "), str...)


#     function register(loop)
#         lock((global LOCK)) do
#             push!((global INDEX), loop)
#         end
#         nothing
#     end

#     index() = return (global INDEX)
# end