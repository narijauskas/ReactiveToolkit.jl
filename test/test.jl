using ReactiveToolkit
using MacroTools

x = Topic()

(@macroexpand @loop "name" () () ()) |> MacroTools.prettify

tasks = RTk.Loop[]
tk = @loop "task name" () (sleep(1)) ()
push!(tasks, tk)

tk = @loop "task name" sleep(1)