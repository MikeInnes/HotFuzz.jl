immutable History
  data::Vector{Bool}
end

History() = History([])

Base.push!(h::History, x::Bool) = push!(h.data, x)

branch!(h::History, x::Bool) = (push!(h, x); x)

@inline trace(f, hist, xs...) = f(xs...)

function tracemethod!(l::LambdaInfo)
  F = l.specTypes.parameters[1]
  switchfunc!(l, trace)
  insertarg!(l, 2, (symbol("#unused#"),F))
  insertarg!(l, 3, (:history,History))
  map!(l.code) do ex
    isexpr(ex, :gotoifnot) || return ex
    Expr(:gotoifnot,
         Expr(:call, GlobalRef(HotFuzz, :branch!), SlotNumber(3), ex.args[1]),
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
