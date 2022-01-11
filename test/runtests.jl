using ReactiveToolkit, Test, SafeTestsets

@time begin
    @time @safetestset "Time & Frequency" begin include("test_times.jl") end
    @time @safetestset "Signals" begin include("test_signals.jl") end
    # @time @safetestset "Reactions" begin include("test_reactions.jl") end
end