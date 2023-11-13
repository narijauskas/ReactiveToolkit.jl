using ReactiveToolkit, Test
using ReactiveToolkit: isactive

delay() = sleep(0.3)

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

@testset "@on macro" begin
    @topic x = 0
    @topic y = 0

    # starting a task
    tk = @on x y[] = x[]
    delay()
    @test isactive(tk)

    # reactive triggering
    x[] = 1
    @test y[] == 1
    x[] = 2
    @test y[] == 2
    x[] = 3
    @test y[] == 3

    # killing a task
    kill(tk)
    delay()
    @test !isactive(tk)
end