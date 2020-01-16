// @_specialize(where T == UInt16)
func f<T: BinaryInteger>(_ v: T) -> String {
    v.description
}

_ = f(UInt16(9))