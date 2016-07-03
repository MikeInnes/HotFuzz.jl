immutable Location
  file::String
  line::Int
end

const nofile = Location("",-1)

type Branch
  loc::Location
end

immutable History
  data::Vector{Tuple{Branch,Bool}}
end

History() = History([])

Base.push!(h::History, x::Tuple{Branch,Bool}) = push!(h.data, x)

branch!(h::History, b::Branch, x::Bool) = (push!(h, (b, x)); x)

@inline trace(f, hist, xs...) = f(xs...)

function tracemethod!(l::LambdaInfo)
  F = l.specTypes.parameters[1]
  switchfunc!(l, trace)
  insertarg!(l, 2, (symbol("#unused#"),F))
  insertarg!(l, 3, (:history,History))
  loc = nofile
  map!(l.code) do ex
    isexpr(ex, :line) && (loc = Location(string(ex.args[2]), ex.args[1]))
    isa(ex, LineNumberNode) && (loc = Location(loc.file, ex.line))
    isexpr(ex, :gotoifnot) || return ex
    Expr(:gotoifnot,
         Expr(:call, GlobalRef(HotFuzz, :branch!), SlotNumber(3), Branch(loc), ex.args[1]),
         ex.args[2])
  end
  return l
end

function trace!(meth::Method)
  linfo = copy(meth.lambda_template)
  tracemethod!(linfo)
  jl_method_def(linfo)
  return
end

function runtrace(f, args...)
  h = History()
  trace(f, h, args...), h.data
end

# trace!(@which(gcd(1, 1)))

# runtrace(gcd, rand(0:100), rand(0:100))
