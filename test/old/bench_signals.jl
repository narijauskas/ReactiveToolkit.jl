using ReactiveToolkit, Test
using Base.Threads: @spawn

const s1 = Signal{Int}(0)


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
