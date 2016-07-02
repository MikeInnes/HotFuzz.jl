import Base: svec

Base.LambdaInfo() = ccall(:jl_new_lambda_info_uninit, Ref{LambdaInfo}, (Ptr{Void},), C_NULL)

function Base.copy(l::LambdaInfo)
  l′ = LambdaInfo()
  for f in fieldnames(l)
    isdefined(l, f) || continue
    val = getfield(l, f)
    isa(val, Array) && (val = copy(val))
    setfield!(l′, f, val)
  end
  return l′
end

function uncompress!(l::LambdaInfo)
  l.code = Base.uncompressed_ast(l)
  return l
end

typealias TupleType{T<:Tuple} Type{T}

jl_method_def(argdata::SimpleVector, f::LambdaInfo, isstaged::Bool = false) =
  ccall(:jl_method_def, Void, (Any, Any, Any), argdata, f, isstaged)

jl_method_def(types::TupleType, tvars::SimpleVector, f::LambdaInfo, isstaged::Bool = false) =
  jl_method_def(svec(types, tvars), f, isstaged)

tovec(sv::SimpleVector) = sv
tovec(x) = svec(x)

jl_method_def(f::LambdaInfo, isstaged = false) =
  jl_method_def(f.specTypes, tovec(f.def.tvars), f, isstaged)

function switchfunc!(l::LambdaInfo, f)
  l.specTypes = Tuple{typeof(f), l.specTypes.parameters[2:end]...}
  return l
end

function bump_slots!(l::LambdaInfo, start::Integer)
  map!(uncompress!(l).code) do ex
    MacroTools.prewalk(ex) do x
      isa(x, SlotNumber) && x.id ≥ start ? SlotNumber(x.id+1) :
      isa(x, NewvarNode) && x.slot.id ≥ start ? NewvarNode(SlotNumber(x.slot.id + 1)) :
      x
    end
  end
  return l
end

function insertarg!(l::LambdaInfo, n::Integer, v::Tuple{Symbol,Type})
  name, T = v
  insert!(l.slotnames, n, name)
  insert!(l.slotflags, n, 0)
  l.specTypes = Tuple{insert!(collect(l.specTypes.parameters), n, T)...}
  l.nargs += 1
  bump_slots!(l, n)
  return l
end
