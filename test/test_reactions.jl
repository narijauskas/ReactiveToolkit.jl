using ReactiveToolkit, Test
RTk = ReactiveToolkit
on = RTk.on # GLMakie conflict

# priority - low latency

const s1 = Signal(0)
const s2 = Signal(0)
const s3 = Signal(0)
const s4 = Signal(0)

const s4 = Signal(0)


rt1 = on(s1) do
    println("hello from thread $(Threads.threadid())")
end


# block for ns
function block(ns::Nanosecond)
    t₀ = now()
    while now() - t₀ < ns
    end 
end

# yield for ns
function nanosleep(ns::Nanosecond)
    t₀ = now()
    while now() - t₀ < ns
        yield()
    end 
end



rt2 = on(s1) do
   s2[] += 1
end


rt3 = on(s1) do
    s3[] = s1[]
end


rt4 = on(s2) do
    s4[] += 1
end

## ------------------------------------  ------------------------------------ #

s1[] = 0
s2[] = 0
s3[] = 0
s4[] = 0

let n = 1000
    for ix in 1:n
        s1[] = ix
        yield()
        block(μs(100))
    end

    @show s1[]
    @show s2[] # number of notify's
    @show s3[] # last number
    @show s4[]

    return s1[] == s2[] == s3[] == n
end

## ------------------------------------  ------------------------------------ #



RTk.disable!(rt1)
RTk.disable!(rt2)
RTk.disable!(rt3)
RTk.disable!(rt4)

lock(s1.cond) do
    notify(s1.cond, RTk.TaskDone(); error=true)
end