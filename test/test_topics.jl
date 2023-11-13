using ReactiveToolkit, Test
using ReactiveToolkit: isactive

delay() = sleep(0.2)

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

    # starting/stopping a task
    tk = @on x y[] = x[]
    while !isactive(tk)
        sleep(0.1)
    end
    @test isactive(tk)
    @test istaskstarted(tk.task)
    @test x[] == 0
    @test y[] == 0
    kill(tk)
    while isactive(tk)
        sleep(0.1)
    end
    @test !isactive(tk)
    @test istaskdone(tk.task)

    # reactive triggering
    tk = @on x y[] = x[]
    delay()
    x[] = 1
    sleep(0.001)
    @test y[] == 1
    x[] = 2
    sleep(0.001)
    @test y[] == 2
    x[] = 3
    sleep(0.001)
    @test y[] == 3

    # kill the task
    kill(tk)
    delay()
    @test !isactive(tk)
end

@testset "multiple @on tasks" begin
    @topic x = 0
    @topic y = 0
    @topic z = 0

    tk1 = @on x y[] = x[]
    tk2 = @on x z[] = x[]
    delay()

    x[] = 1
    sleep(0.001)
    @test x[] == 1
    @test y[] == 1
    @test z[] == 1

    kill(tk2)
    delay()
    x[] = 2
    sleep(0.001)
    @test x[] == 2
    @test y[] == 2
    @test z[] == 1

    kill(tk1)
    delay()
    x[] = 3
    sleep(0.001)
    @test x[] == 3
    @test y[] == 2
    @test z[] == 1
end


@testset "@every macro" begin

    # make a topic
    @topic x = 0
    # make a task that should update faster than any OS scheduler allows
    tk = @every micros(100) x[] = x[] + 1
    delay() # let the task start up
    @test isactive(tk)
    x[] = 0
    sleep(0.1)
    @test x[] >= 1000
    @test x[] < 2000
    sleep(0.1)
    @test x[] >= 2000
    @test x[] < 3000

    # kill the task
    kill(tk)
    delay()
    @test !isactive(tk)
end


@testset "chaining tasks" begin

    @topic x = 0
    @topic y = 0
    @topic z = 0.0

    tk1 = @every millis(10) x[] = x[] + 1
    tk2 = @on x y[] = x[]
    tk3 = @on y z[] = sin(y[])
    tks = [tk1, tk2, tk3]
    delay()
    delay()

    @test z[] == sin(y[])
    z_last = z[]
    delay()
    @test z[] != z_last
    @test z[] == sin(y[])
    z_last = z[]
    delay()
    @test z[] != z_last
    @test z[] == sin(y[])

    # kill_all()
    kill.(tks)
    delay()
    @test !any(isactive.(tks))
    # @test !isactive(tk)
end

@testset "initializers/finalizers" begin
    # initializers/finalizers
    @topic x = 0
    @topic y = 0

    @test x[] == 0

    tk = @on y begin # initializer
        x[] = 1
    end begin # loop
        x[] = y[]
    end begin # finalizer
        x[] = 7
    end

    delay()
    @test isactive(tk)
    @test x[] == 1
    @test y[] == 0
    @test x[] != y[]
    y[] = 2
    sleep(0.001)
    @test x[] == 2
    @test x[] == y[]
    y[] = 3
    sleep(0.001)
    @test x[] == 3
    @test x[] == y[]
    kill(tk)
    delay()
    @test !isactive(tk)
    @test x[] == 7
    @test y[] == 3
    @test x[] != y[]
end



# @testset "@every macro - polling" begin
#     # test a polling reaction
#     @topic x = 0
#     @topic y = 0

#     # starting a task
#     tk = @every millis(10) y[] = x[]
#     delay()
#     @test isactive(tk)

#     # reactive triggering
#     x[] = 1
#     delay()
#     @test y[] == 1
#     x[] = 2
#     delay()
#     @test y[] == 2
#     x[] = 3
#     delay()
#     @test y[] == 3

#     # kill the task
#     kill(tk)
#     delay()
#     @test !isactive(tk)
# end

@testset "making 100 tasks by loop" begin
    x = Topic("x", 0)
    y = [Topic("y$i", 0) for i in 1:100]
    # tasks = [(@on x y[i][] = x[]) for i in 1:100]
    tasks = [(@on x yi[] = x[]) for yi in y]
    delay()
    delay()

    @test sum([yx[] == x[] for yx in y]) == 100
    x[] = 1
    sleep(0.01)
    @test sum([yx[] == x[] for yx in y]) == 100
    x[] = 2
    sleep(0.001)
    @test sum([yx[] == x[] for yx in y]) == 100
    kill(tasks[3])
    delay()
    x[] = 3
    sleep(0.001)
    @test sum([yx[] == x[] for yx in y]) == 99
    kill.(tasks[1:50])
    delay()
    x[] = 4
    sleep(0.001)
    @test sum([yx[] == x[] for yx in y]) == 50
    kill.(tasks)
    delay()
    x[] = 5
    sleep(0.001)
    @test sum([yx[] == x[] for yx in y]) == 0
end