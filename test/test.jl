using ReactiveToolkit
using MacroTools
using Unitful

x = Topic()
y = Topic()

tk = @on [x,y] println(y[])

# y[] = 3
# x[] = 1

# kill(tk)