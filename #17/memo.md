# わいわいswiftc #17
# Genericsの特殊化

# Generics関数が特殊化されるということ

- 今回指す特殊化は、コンパイル時の最適化としてgenerics関数の型パラメータが実際の型が埋め込まれた形で展開されて型ごとに専用の実装が生えるもののことを指す

```swift
func f<T>(_ v: T) {}
f(1)
```

↓ 最適化されてIntが埋め込まれたfができるコレ

```swift
func f<T>(_ v: T) {}
func f(_ v: Int) {}
f(1)
```

最終的にはこうなってなくなることが多い

```swift
func f<T>(_ v: T) {}
```


- いつもの便利な図でSILGENのココのフェーズで最適化されるんだよということを説明
- classやstructは特殊化されない
    - 少なくとも僕は観測できなかった
    - 特殊化された型を特殊化実装のないgenecics関数に投げれない
    - そもそも必要ない？
- 1_struct/generics.swift をコンパイルしてSILやSILの最適化経路をみて挙動を確認
- 3_function/generics.swift をコンパイルしてSILやSILの最適化経路をみて挙動を確認
    - この2つに大差はない

# @_specializeによる特殊化
これはちょっと番外的なものなので差し込む場所を要検討。
時間余ったら枠でいいかもしれない

- @_specialize(where T == Int) みたいなattributeを書くと強制的に特殊化できるが、内部で型による分岐が走るだけである

```swift
// @_specialize(where T == Int)
func f<T: BinaryInteger>(_ v: T) -> String {
    v.description
}
```

```swift
// @_specialize(where T == Int)
func f<T: BinaryInteger>(_ v: T) -> String {
    if T.self == Int.self {
        return v.description // ← vが最初からIntということになってる
    } else {
        return v.description // ← Tのwitness tableからdescription関数を取り出してから実行する
    }
}
```

# 具体的なSILOptimizerにおける最適化プロセス
ここからがむずい。

- SILOptimizerの1つに GenericSpecializer があり、ここで特殊化が行われる
- 

- 特殊化される手順
1. ownershipを持つなら除外（よくわかってない）（未実装なだけで将来的には対応するらしい）
2. 型パラを持ち、呼び出し先が参照可能なapply命令を集める（外部モジュールとかを除外）
3. 非特殊化指定アノテーションつきを除外
4. dynamicつきfuncを除外
5. 特殊化を試みる。Generics.cppに移動。
6. その時点で呼び出し可能性のある関数にarchetype持ちがある場合は失敗。
    - archetypeは実行時に決まる型
    - archetypeについては https://blog.waft.me/2017/12/04/swift-type-system-15/
    - このフェーズはあとで挽回できる（同じ関数に対する呼び出しがすべて特殊化されたらarchetypeがなくなり突破できる）
7. `Self`の呼び出し可能性が残りきっているなら失敗
8. 型が複雑すぎたら失敗。以下のどちらかで失敗
    - 型パラネスト含め50個以上
    - TypeWidth（よくわからない）が2000以上
        - 関数型なら引数と返り値の数が2000個以上とか、NominalTypeDescriptorのプロパティ数2000個以上とか
        - 検証できてない。プロパティ2000個はひっかからなかった
9. 特殊化の無限ループが起こりうるなら失敗
    - 検証ロジックが解読できてない


## 1. ownershipを持たない（よくわかってない）（未実装なだけで将来的には対応するらしい）
こんな感じのコード書いても最適化されるっぽかった。わからん
```swift
struct A<T> {
    var _v: T
    var v: T {
        get {
            _v
        }
        _modify {
             yield &_v
        }
    }
}

var a = A(_v: 0)
a.v = 1 // generic specialization <Swift.Int> of test.A.v.modify : A

func useA<T>(_ a: __owned A<T>) -> T {
    a.v
}

useA(a) // generic specialization <Swift.Int> of test.useA<A>(__owned test.A<A>) -> A
```