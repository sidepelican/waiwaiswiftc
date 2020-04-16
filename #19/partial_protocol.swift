protocol P {
    func f<T>(_ v: T) -> Bool
}

struct A: P {
    func f<T>(_ v: T) -> Bool {
        T.self == A.self
    }
}

struct B: P {
    func f<T>(_ v: T) -> Bool {
        false
    }
}

@inline(never)
func makeAorB() -> P {
    B()
}

func g() -> Bool {
    makeAorB().f(UInt16(9))
}
