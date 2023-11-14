using ReactiveToolkit, Test

@testset "@on macro" begin
    @topic x = 0
    @topic y = 0

    # starting/stopping a task
    tk = @on x y[] = x[]
    while !isactive(tk)
        sleep(0.1)
    end
    @test tk isa ReactiveTask
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
    tk0 = @every micros(100) x[] = x[] + 1
    start_stop(tk0) # let the machinery compile

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