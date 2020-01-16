class C {
    let v : Int32
    required init(_ v: Int32) {
        self.v = v
    }

    class func Factory<T: P>(_ v: T, _ s: C) -> Self {
        var r = self.init(8)
        return r
    }
}

class D: C {
    override class func Factory<T: P>(_ v: T, _ s: C) -> Self {
        var r = self.init(10)
        return r
    }
}

protocol P {}
extension Int16: P {}

@inline(never)
func makeCorD() -> C {
    D(7)
}

let d = makeCorD()

_ = type(of: d).Factory(Int16(9), d)
