# compound tests which test multiple parts of the package working together
using ReactiveToolkit, Test

@testset "chaining tasks" begin

    @topic x = 0
    @topic y = 0
    @topic z = 0.0

    tk1 = @every millis(50) x[] = x[] + 1
    tk2 = @on x y[] = x[]
    tk3 = @on y z[] = sin(y[])
    tks = [tk1, tk2, tk3]
    sleep(0.5)

    @test any([(sleep(0.01); sin(y[]) == z[]) for i in 1:3])
    z_last = z[]

    @test any([(sleep(0.01); sin(y[]) == z[]) for i in 1:3])
    @test z[] != z_last
    z_last = z[]

    @test any([(sleep(0.01); sin(y[]) == z[]) for i in 1:3])
    @test z[] != z_last

    # kill_all()
    kill.(tks)
    delay()
    @test !any(isactive.(tks))
    # @test !isactive(tk)
end


@testset "task/topic generators" begin
    x = Topic(0; name="x")
    y = [Topic(0; name="y$i") for i in 1:100]
    # tasks = [(@on x y[i][] = x[]) for i in 1:100]
    tasks = [(@on x "x->$(yi.name)" yi[] = x[]) for yi in y]
    delay()
    delay()

    @test sum([yx[] == x[] for yx in y]) == 100
    x[] = 1
    sleep(0.1)
    @test sum([yx[] == x[] for yx in y]) == 100
    x[] = 2
    sleep(0.01)
    @test sum([yx[] == x[] for yx in y]) == 100
    kill(tasks[3])
    delay()
    x[] = 3
    sleep(0.01)
    @test sum([yx[] == x[] for yx in y]) == 99
    kill.(tasks[1:50])
    delay()
    delay()
    x[] = 4
    sleep(0.01)
    @test sum([yx[] == x[] for yx in y]) == 50
    kill.(tasks)
    delay()
    x[] = 5
    sleep(0.01)
    @test sum([yx[] == x[] for yx in y]) == 0
end

@testset "@after macro" begin

    tk1 = @after seconds(1) begin
        i = 0
        task = @every millis(5) println("hello! i=$(i+=1)")
        @after seconds(1) kill(task)
    end
    delay()
    @test isactive(tk1)
    sleep(2)
    @test !isactive(tk1)
    @test_throws UndefVarError i

    @topic j = 0
    tk2 = @after seconds(1) begin
        task = @every millis(5) println("hello! j[]=$(j[]+=1)")
        @after seconds(1) kill(task)
    end
    delay()
    @test isactive(tk2)
    sleep(2)
    @test !isactive(tk2)
    @test 200 == j[]
end