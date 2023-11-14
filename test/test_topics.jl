using ReactiveToolkit, Test
using ReactiveToolkit: isactive


@testset "@topic construction" begin

    # basic construction
    @topic x::Int = 0
    @test x.name == "x"
    @test x.t_last <= now()
    @test x isa Topic{Int}
    @test x[] isa Int

    # type inference
    @topic x = 0
    @test x isa Topic{Int}
    @test x[] isa Int

    # narrowing conversion
    @topic x::Int = 0.0
    @test x isa Topic{Int}
    @test x[] isa Int

    # widening conversion
    @topic x::Float64 = 0
    @test x isa Topic{Float64}
    @test x[] isa Float64

    # abstract types
    @topic x::Number = 0
    @test x isa Topic{Number}
    @test x[] isa Number
    @test x[] isa Int

    @topic x::Any = 0.0
    @test x isa Topic{Any}
    @test x[] isa Any
    @test x[] isa Float64

    # variable length arrays
    @topic x = [1, 2, 3]
    @test x isa Topic{Vector{Int}}
    @test x[] isa Vector{Int}
end


@testset "topic modification" begin

    # primitive types
    @topic x::Int = 0
    @test x[] == 0
    @test x[] isa Int
    x[] = 1
    @test x[] == 1
    @test x[] isa Int
    x[] = 2.0
    @test x[] == 2
    @test x[] isa Int

    # abstract types
    @topic x::Number = 0
    @test x[] == 0
    @test x[] isa Int
    x[] = 1.5
    @test x[] == 1.5
    @test x[] isa Float64
    x[] = 1+2im
    @test x[] == 1+2im
    @test x[] isa Complex{Int}

    # variable length arrays
    @topic x = [1, 2, 3]
    @test x isa Topic{Vector{Int}}
    @test x[] == [1, 2, 3]
    @test x[] isa Vector{Int}
    @test length(x[]) == 3
    x[] = repeat([1,2], 10)
    @test x[] == repeat([1,2], 10)
    @test x[] isa Vector{Int}
    @test length(x[]) == 20
end

@testset "topic capacity" begin
    x = Topic{Number}(0; size = 100)
    @test 100 == length(x) skip = true
    @test x[:] == zeros(100)
end

