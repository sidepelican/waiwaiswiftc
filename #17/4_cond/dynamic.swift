class A {
    dynamic func f<T>(_ v: T) {
    }

    func g<T>(_ v: T) {
    }
}

A().f(UInt16((9)))
A().g(UInt16((9)))
