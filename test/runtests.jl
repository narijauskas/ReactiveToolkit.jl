using RectiveToolkit, Test, SafeTestsets

@time begin
    @time @safetestset "Time & Frequency" begin include("test_times.jl") end
    @time @safetestset "Signals" begin include("test_signals.jl") end
end