@topic x=1
Topic{Float64}("x", 1)

tk1 = @loop "name" begin
end

tk2 = @on x "name" begin
end

tk3 = @on x y[] = sin(x[])

tk4 = @at Hz(1) "name" begin
end

# wait a certain amount
# kill!(tk4)
# 