import NumLeanPerf.Data.UIntRange

namespace FloatArray

@[extern "lean_float_array_unsafe_set"]
opaque unsafeSet (xs : FloatArray) (i : USize) (x : Float) : FloatArray

end FloatArray
