using ReactiveToolkit, Test, SafeTestsets, BenchmarkTools

# Level 1 Tests: functionality/unit testing
@time begin
    @time @safetestset "Time & Frequency" begin include("test_times.jl") end
    @time @safetestset "Signals" begin include("test_signals.jl") end
    # @time @safetestset "Reactions" begin include("test_reactions.jl") end
end

# Level 2 Tests: performance/regression
#=
@time begin
    # @time @safetestset "Time & Frequency" begin include("bench_times.jl") end
    @time @safetestset "Signal Benchmarks" begin include("bench_signals.jl") end
    # @time @safetestset "Reactions" begin include("bench_reactions.jl") end
end
=#