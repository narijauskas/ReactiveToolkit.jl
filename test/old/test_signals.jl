using ReactiveToolkit, Test
using Base.Threads: @spawn

#FUTURE: test @inferred for type stability
#MAYBE: formally test thread-safety?




## ------------------------------------ basics ------------------------------------ ##
const s1 = Signal{Int}(0)
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





# errors/invalid types



## ------------------------------------ wait/notify ------------------------------------ ##
s2[] = 0

@spawn begin
    wait(s1)
    s2[] = s1[]
end

sleep(0.1)
s1[] = 1
sleep(0.1)
@test 1.0 === s2[]


#TODO: reactivity, @on

## ------------------------------------ threading/races ------------------------------------ ##
#FUTURE:
# make a Topic{Vector}, try to simultaneously modify vector elements from multiple threads
# eg. x[][i] = v