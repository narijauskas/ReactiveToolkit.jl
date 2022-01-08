using Graphs, GLMakie, GraphMakie

g = SimpleGraph(3)
add_edge!(g, 1, 2)

fg, ax, p = graphplot(g)
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()
fg
