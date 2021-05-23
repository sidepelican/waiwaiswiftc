---
marp: true
paginate: true
size: 16:9
---

## わいわいswiftc #28

# Publisher@resultBuilder

Twitter @iceman5499

<!-- _footer: 2021年5月28日 -->

---

## resultBuilderの簡単な説明

Swift5.1から登場(※)した、式を宣言する形式の文法でコードを記述できるようにする仕組み。

https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md


```swift
// SwiftUIの例
@ViewBuilder var body: some View {
  VStack {
    Text("Hello")
    Spacer()
  }
}
```

`@ViewBuilder`はresultBuilderの一種で、SwiftUI.frameworkによって用意されている。`@ViewBuilder`自体は言語機能ではなくあくまで実装。自分たちで同じものを作ることが出来る。

<!-- _footer: ※Swift5.1時点では@_functionBuilderという名前だった -->

---

## 今回の目的

`Combine`フレームワークを用いる際の手間のかかる`Publisher`の組み立てをresultBuilderを使って楽できるようにする

---

## Combineを使って感じる課題: Publisherの分岐が大変

```swift
func f() -> AnyPublisher<Int, Error> {
  nanikaPublisher
    .flatMap { v -> AnyPublisher<Int, Error> in // 返り値の型は省略できないことが多い
      if v.isXxx {
        return PassthroughSubject<Int, Never>()
          .setFailureType(to: Error.self) // Never川をError川として返す場合はエラー型を指定
          .eraseToAnyPublisher() // 型消去がほぼ必須
      } else {
        return PassthroughSubject<Int, Error>()
          .eraseToAnyPublisher() // 型消去が分岐ごとに必要
      }
    }
    .eraseToAnyPublisher()
}
```

flatMapを書く際など、型の変換が面倒だったり型推論がうまくいかなくて困ることがある。

---

## 解決方法

### resultBuilderで型推論器にヒントを与え、かつ間に処理を差し込んで暗黙的な変換ができるようにする

```swift
func f() -> AnyPublisher<Int, Error> {
  nanikaPublisher
    .flatMapBuild { v in
      if v.isXxx {
        PassthroughSubject<Int, Never>()
      } else {
        PassthroughSubject<Int, Error>()
      }
    }
    .eraseToAnyPublisher()
}
```
resultBuilderを使うと↑をvalidなコードとすることができる

---


---