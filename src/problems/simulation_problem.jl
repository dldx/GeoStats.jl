## Copyright (c) 2017, Júlio Hoffimann Mendes <juliohm@stanford.edu>
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted, provided that the above
## copyright notice and this permission notice appear in all copies.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
## WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
## ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
## WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
## ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
## OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""
    SimulationProblem(geodata, domain, targetvars)
    SimulationProblem(domain, targetvars)

A spatial simulation problem on a given `domain` in which the
variables to be estimated are listed in `targetvars`. For
conditional simulation, the data of the problem is stored in
`geodata`.

### Notes

For unconditional simulation, an empty `geodata` object is
automatically created by the constructor. Therefore, all
simulation solvers can assume that a valid (possibly empty)
[`GeoDataFrame`](@ref) exists.
"""
struct SimulationProblem{D<:AbstractDomain} <: AbstractProblem
  geodata::GeoDataFrame
  domain::D
  targetvars::Vector{Symbol}

  function SimulationProblem{D}(geodata, domain, targetvars) where {D<:AbstractDomain}
    @assert targetvars ⊆ names(data(geodata)) "target variables must be columns of geodata"
    @assert isempty(targetvars ∩ coordnames(geodata)) "target variables can't be coordinates"
    @assert ndims(domain) == length(coordnames(geodata)) "data and domain must have the same number of dimensions"

    new(geodata, domain, targetvars)
  end
end

SimulationProblem(geodata, domain, targetvars) =
  SimulationProblem{typeof(domain)}(geodata, domain, targetvars)

SimulationProblem(geodata, domain, targetvar::Symbol) =
  SimulationProblem(geodata, domain, [targetvar])

function SimulationProblem(domain, targetvars)
  dim = ndims(domain)
  ctypes = [coordtype(domain) for i=1:dim]
  vtypes = [Float64 for i=1:length(targetvars)]
  cnames = [Symbol("x$i") for i=1:dim]
  vnames = targetvars
  nodata = DataFrame([ctypes...,vtypes...], [cnames...,vnames...], 0)

  geodata = GeoDataFrame(nodata, cnames)

  SimulationProblem(geodata, domain, targetvars)
end

SimulationProblem(domain, targetvar::Symbol) = SimulationProblem(domain, [targetvar])

"""
    hasdata(simproblem)

Return true if simulation problem `simproblem` has data
(i.e. conditional simulation) and false otherwise.
"""
hasdata(problem::SimulationProblem) = npoints(problem.geodata) > 0

"""
    SimulationSolution

A solution to a spatial simulation problem.
"""
struct SimulationSolution{D<:AbstractDomain} <: AbstractSolution
  domain::D
  realizations::Dict{Symbol,Vector{Vector}}
end

SimulationSolution(domain, realizations) =
  SimulationSolution{typeof(domain)}(domain, realizations)

# ------------
# IO methods
# ------------
function Base.show(io::IO, problem::SimulationProblem{D}) where {D<:AbstractDomain}
  dim = ndims(problem.domain)
  kind = hasdata(problem) ? "conditional" : "unconditional"
  print(io, "$(dim)D SimulationProblem ($kind)")
end

function Base.show(io::IO, ::MIME"text/plain", problem::SimulationProblem{D}) where {D<:AbstractDomain}
  println(io, problem)
  println(io, "  data:      ", problem.geodata)
  println(io, "  domain:    ", problem.domain)
  print(  io, "  variables: ", join(problem.targetvars, ", ", " and "))
end
