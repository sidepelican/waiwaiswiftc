---
marp: true
paginate: true
size: 16:9
---

<style>
.codegenbox {
    display: flex;
    flex-direction: row;
    align-items: start;
    width: 100%;
}
.codegenbox > .code {
    flex: 1;
}
.codegenbox > .arrow {
    padding: 10px; 
    align-self: center;
}
</style>

## わいわいswiftc #35

# サーバ上のasync関数をクライアントから呼び出すコード生成技術

Twitter @iceman5499

<!-- _footer: 2022年4月25日 -->

---

# 既存コード生成技術の紹介

- ステンシルを書いてテンプレート出力する系
    - SwiftGen/SwiftGen
    - krzysztofzablocki/Sourcery
- 単一の高度な機能を提供する系
    - uber/mockolo
    - uber/needle

SwiftGen以外は全てSwiftSyntaxを用いている

---

## SwiftSyntaxの課題

多くのコード生成ライブラリはSwiftSyntaxを利用しているが、Xcodeとバージョンを揃えて使う必要があって地味に大変
→ BetaなXcodeを使用しているなどで利用できない
→ Xcodeから実行する際に環境変数の指定が必要

---

## 使いやすさの問題

- stencilファイルの難しさ（SwiftGen, Sourcery）
	- 独自文法を勉強するのが大変
	- できない表現があったりして、代替案を頑張って模索する
		- regexが使えないなど: https://github.com/SwiftGen/StencilSwiftKit/pull/123
	- 魔術的なコードになりやすい

---

## 使いやすさの問題

- 自由度の課題
	- ライブラリが提供する表現力の範囲でしかコード生成できない
	- オプションで切り替えられる範囲にも限度がある

<br>

→ ライブラリが想定する使い方の範囲で強く効果を発揮する
→ 自分のプロジェクトのほうをライブラリの思想に合わせて設計する必要がある

---

# BinarySwiftSyntax & SwiftTypeReader

- BinarySwiftSyntax
	- ローカルのXcode依存を回避
- SwiftTypeReader
	- コード生成器を自作しやすくする

---

# 作例紹介

---

# CodableToTypeScript

--- 

# CodableToTypeScript
 
- SwiftのCodableな型をTypeScriptの型に変換する

例1: シンプルなCodable

<div class=codegenbox>
<div class=code>

```swift
public struct Foo: Codable {
    public var bar: URL
    public var baz: [String]
}
```
</div>
<p class=arrow>→</p>
<div class=code>

```typescript
export type Foo = {
    bar: string;
    baz: string[];
};
```
</div>
</div>

--- 

# CodableToTypeScript
 
例2: 文字列enum

<div class=codegenbox>
<div class=code>

```swift
public enum Language: String, Codable {
    case ms
    case en
    case ja
}
```
</div>
<p class=arrow>→</p>
<div class=code>

```typescript
export type Language = "ms" |
"en" |
"ja";
```
</div>
</div>

--- 

# CodableToTypeScript
 
<div class=codegenbox>
<div class=code>

例3: 値付きenum

```swift
public enum FilterItem: Codable, Equatable {
    case name(String)
    case email(String)
}
```

- `~~~Decode`関数も自動で生成される
- `kind`を追加することでswitchにおける網羅チェックとsmart castを有効にしている

</div>
<p class=arrow style="align-self: start; padding-top: 90px">→</p>
<div class=code style="flex: 1.5">

```typescript
export type FilterItemJSON = {
    name: {
        _0: string;
    };
} | {
    email: {
        _0: string;
    };
};

export type FilterItem = {
    kind: "name";
    name: {
        _0: string;
    };
} | {
    kind: "email";
    email: {
        _0: string;
    };
};

export function FilterItemDecode(json: FilterItemJSON): FilterItem {
    if ("name" in json) {
        return { "kind": "name", name: json.name };
    } else if ("email" in json) {
        return { "kind": "email", email: json.email };
    } else {
        throw new Error("unknown kind");
    }
}
```
</div>
</div>

--- 

# CodableToTypeScript

使用例:

```typescript
switch (filter.kind) { // ← kindがあると網羅チェックとキャストができる
case "name":
    const name = filter.name._0; // .nameをエラー無しに参照できる
    ...
case "email":
    const email = filter.email._0; // .emailをエラー無しに参照できる
    ...
}
```

---

# CodableToTypeScript

## 実装詳細



---


# CallableKit

- サーバ上のSwift関数をクライアントから実行するためのスタブを生成

例:

---

## 実装詳細

- 通信方式には依存しておらず、通信部分の実装は状況に応じて決める
- 現在はREST風でJSONをやりとりし、HTTPの通信にVaporを利用している
	- Vaporに直接依存していないので、将来的にVaporを剥がすことが容易

---

## Typescript版クライアント

- CodableToTypeScriptと組み合わせて、TypeScriptクライアントもコード生成













