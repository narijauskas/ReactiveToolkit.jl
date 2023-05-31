using Test
using ReactiveToolkit
using ReactiveToolkit: Nanos

@testset "time constructors" begin
    @test nanos(1) == Nanos(1)
    @test micros(1) == Nanos(1e3)
    @test millis(1) == Nanos(1e6)
    @test seconds(1) == Nanos(1e9)
end

@testset "frequency constructors" begin
    @test Hz(1) == Hz(1)
    @test kHz(1) == Hz(1e3)
    @test MHz(1) == Hz(1e6)
    @test GHz(1) == Hz(1e9)
end

@testset "frequency to time conversion" begin
    @test seconds(1) == Nanos(Hz(1))
    @test seconds(0.5) == Nanos(Hz(2))
    @test seconds(1/3) == Nanos(Hz(3))
    @test millis(1) == Nanos(kHz(1))
    @test nanos(1) == Nanos(GHz(1))
end

@testset "time to frequency conversion" begin
    @test Hz(1) == Hz(seconds(1))
    @test Hz(3) == Hz(seconds(1/3))
    @test Hz(5) == Hz(seconds(0.2))
    @test kHz(1) == Hz(millis(1))
    @test GHz(1) == Hz(nanos(1))
end

@testset "conversion decay" begin
    @test Hz(10) == Hz(Nanos(Hz(Nanos(Hz(10)))))
    @test Hz(10) == Hz(Nanos(Hz(seconds(0.1))))

    @test Hz(3) == Hz(Nanos(Hz(Nanos(Hz(3)))))
    @test Hz(3) == Hz(Nanos(Hz(seconds(1/3))))
end

@testset "time comparison" begin
    @test seconds(5) == max(seconds(1), seconds(5))
    @test seconds(3) == min(seconds(3), seconds(8))
end

@testset "time addition/subtraction" begin
    @test seconds(3) == seconds(1) + seconds(2)
    @test seconds(1) == seconds(3) - seconds(2)
end

@testset "negative time" begin
    @test millis(1) == millis(-1)
    @test seconds(1) == seconds(2) - seconds(3)
end

@testset "frequency comparison" begin
    @test kHz(10) == max(Hz(100), kHz(10))
    @test kHz(100) == min(kHz(100), MHz(10))
end

@testset "frequency addition/subtraction" begin
    @test Hz(10) == Hz(5) + Hz(5)
    @test Hz(6) == Hz(2) + Hz(4)
    @test kHz(1) == kHz(2) - kHz(1)
end

@testset "negative frequencies" begin
    @test Hz(-1) == Hz(1)
    @test kHz(-3) == kHz(3)
    @test kHz(1) == kHz(1) - kHz(2)
end

@testset "time multiplication" begin
    @test millis(2) == 2*millis(1)
    @test seconds(1) == 1000*millis(1)
end

@testset "frequency multiplication" begin
    @test Hz(2) == 2*Hz(1)
    @test kHz(3) == 1000*Hz(3)
    @test kHz(3) == 3000*Hz(1)
    @test kHz(3) == 0.003*MHz(1)
end

@testset "time division" begin
    @test 1 == seconds(1)/seconds(1)
    @test 2 == nanos(2)/nanos(1)

    @test millis(500) == seconds(1)/2
    @test micros(1/3) == micros(1)/3
end

@testset "frequency division" begin
    @test 1 == Hz(1)/Hz(1)
    @test 0.5 == MHz(1)/MHz(2)

    @test Hz(0.5) == Hz(1)/2
    @test kHz(1) == MHz(1)/1000
end

@testset "converting division" begin
    @test Hz(1) == 1/seconds(1)
    @test seconds(1) == 1/Hz(1)

    @test kHz(3) == 3/millis(1)
    @test micros(3) == 3/MHz(1)

    @test Nanos(Hz(10)/2) == millis(200)
end

# test show methods
show(seconds(1))
show(millis(1))
show(micros(1))
show(nanos(1))

show(Hz(1))
show(kHz(1))
show(MHz(1))
show(GHz(1))
println()