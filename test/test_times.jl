using ReactiveToolkit, Test

Nano = ReactiveToolkit.Nano

# time constructors
@test ns(1) == Nano(1)
@test μs(1) == Nano(1e3)
@test ms(1) == Nano(1e6)
@test seconds(1) == Nano(1e9)


# frequency constructors
@test Hz(1) == Hz(1)
@test kHz(1) == Hz(1e3)
@test MHz(1) == Hz(1e6)
@test GHz(1) == Hz(1e9)


# conversion between time and frequency
@test seconds(1) == Nano(Hz(1))
@test seconds(0.5) == Nano(Hz(2))
@test seconds(1/3) == Nano(Hz(3))
@test ms(1) == Nano(kHz(1))
@test ns(1) == Nano(GHz(1))

@test Hz(1) == Hz(seconds(1))
@test Hz(3) == Hz(seconds(1/3))
@test Hz(5) == Hz(seconds(0.2))
@test kHz(1) == Hz(ms(1))
@test GHz(1) == Hz(ns(1))


# conversion decay
@test Hz(10) == Hz(Nano(Hz(Nano(Hz(10)))))
@test Hz(10) == Hz(Nano(Hz(seconds(0.1))))

@test Hz(3) == Hz(Nano(Hz(Nano(Hz(3)))))
@test Hz(3) == Hz(Nano(Hz(seconds(1/3))))


# comparing time
@test seconds(5) == max(seconds(1), seconds(5))

# adding/subtracting time
@test seconds(3) == seconds(1) + seconds(2)
@test seconds(1) == seconds(3) - seconds(2)

#inverse time
@test ms(1) == ms(-1)
@test seconds(1) == seconds(2) - seconds(3)

# comparing frequency
@test kHz(10) == max(Hz(100), kHz(10))

# adding/subtracting frequency
@test Hz(10) == Hz(5) + Hz(5)
@test Hz(6) == Hz(2) + Hz(4)
@test kHz(1) == kHz(2) - kHz(1)

# inverse frequency
@test Hz(-1) == Hz(1)
@test kHz(-3) == kHz(3)
@test kHz(1) == kHz(1) - kHz(2)


# multiplying time
@test ms(2) == 2*ms(1)
@test seconds(1) == 1000*ms(1)

# multiplying frequency
@test Hz(2) == 2*Hz(1)
@test kHz(3) == 1000*Hz(3)
@test kHz(3) == 3000*Hz(1)
@test kHz(3) == 0.003*MHz(1)


# dividing time
@test 1 == seconds(1)/seconds(1)
@test 2 == ns(2)/ns(1)

@test ms(500) == seconds(1)/2
@test μs(1/3) == μs(1)/3


# dividing frequency
@test 1 == Hz(1)/Hz(1)
@test 0.5 == MHz(1)/MHz(2)

@test Hz(0.5) == Hz(1)/2
@test kHz(1) == MHz(1)/1000

# converting division
@test Hz(1) == 1/seconds(1)
@test seconds(1) == 1/Hz(1)

@test kHz(3) == 3/ms(1)
@test μs(3) == 3/MHz(1)

@test Nano(Hz(10)/2) == ms(200)

# test show methods
show(seconds(1))
show(ms(1))
show(μs(1))
show(ns(1))

show(Hz(1))
show(kHz(1))
show(MHz(1))
show(GHz(1))
println()