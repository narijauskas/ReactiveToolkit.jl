using Documenter
# using ReactiveToolkit

makedocs(
    # modules = [ReactiveToolkit],
    sitename = "ReactiveToolkit.jl",
    authors = "Mantas Naris",
    pages = Any[
        "Home" => "index.md",
        ],
    doctest=false,
    clean=true,
)

# deploydocs(
#     repo = "github.com/SRTxDojo/SRTxDocs",
#     devbranch = "main"
# )

# using LiveServer

# servedocs(; foldername = ".");
