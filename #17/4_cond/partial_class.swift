class A {
    init() {}

    func f<T>(_ v: T) -> Bool {
        T.self == A.self
    }
}

class B: A {
    override func f<T>(_ v: T) -> Bool {
        false
    }
}

@inline(never)
func makeAorB() -> A {
    B()
}

func g() -> Bool {
    makeAorB().f(UInt16(9))
}
