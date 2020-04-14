func f<T: Equatable>(_ v: T) { v == v }
func g(_ v: Int8) { v == v }
f(Int8(1))
g(Int8(1))
