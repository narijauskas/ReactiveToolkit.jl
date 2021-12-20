
#------------------------------------ signals ------------------------------------#

x = Signal(1)
x = Signal{Int}(1)

x[] = 1
x[] = 1.0

y = x[]


#------------------------------------ tasks ------------------------------------#

on(s...) do
    # stuff with signals
end

every(Hz) do
    # on periodic interval
end

# RepeatingTask - [active]
# repeats every: Hz

# ReactiveTask - [ready]
# reacts to: ...signals...[active]


# y = x^2
y = map(a->a*a, x)
# does this return a Signal? MappedSignal? ReactiveTask?


after(sec) do
    ex 
end
#= becomes (quick and dirty)
    @async begin
        sleep(sec)
        ex
    end
=#

