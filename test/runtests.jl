using ReactiveToolkit, Test
# using SafeTestsets, BenchmarkTools

delay() = sleep(0.2)

function start_stop(tk)
    while !isactive(tk)
        sleep(0.1)
    end
    sleep(0.1)
    kill(tk)
    while isactive(tk)
        sleep(0.1)
    end
    sleep(0.1)
end
# ReactiveToolkit.PRINT_TO_REPL = false


# Level 1: functionality/unit testing
@testset verbose = true "Level 1: Functionality/Unit Testing" begin
    @testset verbose = true "Timing Primitives" include("test_nanos.jl")
    @testset verbose = true "Topic Objects"     include("test_topics.jl")
    @testset verbose = true "Tasks and Macros"  include("test_tasks.jl")
    @testset verbose = true "Compound Tests"    include("test_compound.jl")
    println.(rtk_tasks())
end

#TODO: add more tests for the following:
# manual task name assignment (for @loop, @on, and @every)
#FUTURE: test @inferred for type stability


# Level 2: hardware-in-the-loop
# how to do this reliably?

# Level 3: performance/regression

# println("\nbenchmark-setting signal value:")
# b1 = @benchmark s1[] = 1
# show(stdout, MIME"text/plain"(), b1)
# println()

# println("\nbenchmark-getting signal value:")
# b2 = @benchmark s1[]
# show(stdout, MIME"text/plain"(), b2)
# println()
