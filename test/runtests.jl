using ReactiveToolkit, Test
# using SafeTestsets, BenchmarkTools
delay() = sleep(0.2)

# ReactiveToolkit.PRINT_TO_REPL = false


# Level 1: functionality/unit testing
@testset verbose = true "Level 1: functionality/unit testing" begin
    @testset verbose = true "Timing Primitives" include("test_nanos.jl")
    @testset verbose = true "Topic Objects"     include("test_topics.jl")
    @testset verbose = true "Tasks and Macros"  include("test_tasks.jl")
    @testset verbose = true "Compound Tests"    include("test_compound.jl")
end

#TODO: add more tests for the following:
# manual task name assignment (for @loop, @on, and @every)


# Level 2: hardware-in-the-loop
#=
@time begin
    @time @safetestset "Time & Frequency" begin include("bench_times.jl") end
    @time @safetestset "Signal Benchmarks" begin include("bench_signals.jl") end
    @time @safetestset "Actions" begin include("bench_actions.jl") end
end
=#

# Level 3: performance/regression
#=
@time begin
    @time @safetestset "Time & Frequency" begin include("bench_times.jl") end
    @time @safetestset "Signal Benchmarks" begin include("bench_signals.jl") end
    @time @safetestset "Actions" begin include("bench_actions.jl") end
end
=#