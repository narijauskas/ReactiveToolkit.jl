using Pkg
Pkg.Registry.add("General")
Pkg.Registry.add(RegistrySpec(url="git@github.com:SRTxDojo/SRTxRegistry.git"))
Pkg.add("Documenter")
# Pkg.add("SRTxMCU")
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()