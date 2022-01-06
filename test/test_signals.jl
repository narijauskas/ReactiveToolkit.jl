using ReactiveToolkit, Test

#FUTURE: test @inferred for type stability
#MAYBE: formally test thread-safety?

const s1 = Signal{Int}()
@test s1 isa Signal{Int}
@test 0 === s1[]

s1[] = 1
@test 1 === s1[]
s1[] = 2.0
@test 2 === s1[]

s2 = Signal(2.0)
@test s2 isa Signal{Float64}
@test 2.0 === s2[]

@test eltype(s2) == Float64

# println("\nbenchmark-setting signal value:")
# b1 = @benchmark s1[] = 1
# show(stdout, MIME"text/plain"(), b1)
# println()

# println("\nbenchmark-getting signal value:")
# b2 = @benchmark s1[]
# show(stdout, MIME"text/plain"(), b2)
# println()

# println("\nbenchmark-getting signal time:")
# b3 = @benchmark RealtimeToolkit.gettime(s1)
# show(stdout, MIME"text/plain"(), b3)
# println()
