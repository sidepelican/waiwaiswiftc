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
    public var bar: URL?
    public var baz: [String]
}
```
</div>
<p class=arrow>→</p>
<div class=code>

```typescript
export type Foo = {
    bar?: string;
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
switch (filter.kind) {
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

- SwiftサーバとTypeScriptクライアントな環境において、Swift側の型定義を変更するだけでTS側もコンパイルエラーになってくれる💪
    - enumのcaseを型に表したり値付きenumが使えて便利
    - `.proto`や`.graphql`などの専用の定義ファイルは不要で、Swiftで書ける

- `[T]`を`T[]`に変換したり、`T?`を`T|undefined`として変換できる
- （ある程度は）Genericsにも対応

--- 

# 使い方

- CodableToTypeScript単体はライブラリなので、自前でコード生成用ターゲットを作ってそこから使う

```swift
// Package.swift
.package(url: "https://github.com/omochi/CodableToTypeScript", branch: "main"),

...

.executableTarget(
    name: "CodeGenStage2",
    dependencies: [
        "CodableToTypeScript",
    ]
),
```

--- 

# 使い方

```swift
// main.swift
import SwiftTypeReader
import CodableToTypeScript

let module = try SwiftTypeReader.Reader().read(file: ...).module
let generate = CodableToTypeScript.CodeGenerator(typeMap: .default)
for swiftType in module.types {
    let tsCode = try generate(type: swiftType)
    _ = tsCode.description // TypeScriptコードそのままの文字列になっている
}
```

SwiftTypeReaderで読み取った型をCodableToTypeScriptに渡す

---

# CallableKit

---

# CallableKit

- サーバ上のSwift関数をクライアントから実行するためのスタブを生成
- 定義ファイルから複数のソースを生成
    - サーバ用のルーティング用コード
    - クライアント用のリクエスト用コード
- 雰囲気はgRPCと同じ
    - gRPCよりはかなり薄くて、通信の詳細などは規定せずあくまでインターフェースを定義するだけ
- Swift Distributed Actorsのように、サーバ上のasync関数を呼び出せるようにする

---

# CallableKit

例: 定義ファイル

```swift
public protocol EchoService {
    func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse
}

public struct EchoHelloRequest: Codable, Sendable {
    public var name: String
}

public struct EchoHelloResponse: Codable, Sendable {
    public var message: String
}
```

---

# CallableKit

例: サーバ用ルーティング実装（生成コード）
(VaporかつJSONでやりとりする場合)

```swift
import APIDefinition // 定義ファイルはそのままモジュールとしても利用する
import Vapor

struct EchoServiceProvider<RequestHandler: RawRequestHandler, Service: EchoServiceProtocol>: RouteCollection {
    var requestHandler: RequestHandler
    var serviceBuilder: (Request) -> Service
    init(handler: RequestHandler, builder: @escaping (Request) -> Service) {
        self.requestHandler = handler
        self.serviceBuilder = builder
    }

    func boot(routes: RoutesBuilder) throws {
        routes.group("Echo") { group in
            group.post("hello", use: requestHandler.makeHandler(serviceBuilder) { s in
                try await s.hello()
            })
        }
    }
}
```

- `RouteCollection`なので、Vaporの`RoutesBuilder`にそのままregisterできる

---

# CallableKit

例: クライアント用スタブ実装（生成コード）

```swift
import APIDefinition

public struct EchoServiceStub: EchoServiceProtocol, Sendable {
    private let client: StubClientProtocol
    public init(client: StubClientProtocol) {
        self.client = client
    }

    public func hello(request: EchoHelloRequest) async throws -> EchoHelloResponse {
        return try await client.send(path: "Echo/hello")
    }
}
```

- 生成コードの役割は型をつけるだけなので、送信部分の実装詳細には関与していない

---

## パッケージ構造

```c
.
├── APIDefinition
│   └── Sources
│       └── APIDefinition // 定義だけで実装はなし
│           └── Echo.swift    
├── APIServer
│   └── Sources
│       ├── Service // Serviceの具体的な実装。依存にサーバ用モジュールはなし
│       │   └── EchoService.swift    
│       └── Server // Vaporに依存し、サーバを起動する
│           ├── EchoProvider.gen.swift
│           └── main.swift
├── ClientApp
│   └── Sources
│       └── APIClient
│           └── EchoStub.gen.swift    
```

---

- 通信方式には依存しておらず、通信部分の実装は状況に応じて決める
- 現在はREST風でJSONをやりとりし、HTTPの通信にVaporを利用している
	- Vaporに直接依存していないので、将来的にVaporを剥がすことが容易
    - シリアライズにprotobufなども採用可能
        - 現在は扱いやすさの点でJSONにしてる

---

## Typescript版クライアント

- CodableToTypeScriptと組み合わせて、TypeScriptクライアントもコード生成

---

## Typescript版クライアント

例: TS版クライアント用スタブ実装（生成コード）
```typescript
import { IRawClient } from "./common.gen";

export interface IEchoClient {
  hello(request: EchoHelloRequest): Promise<EchoHelloResponse>
}

class EchoClient implements IEchoClient {
  rawClient: IRawClient;

  constructor(rawClient: IRawClient) {
    this.rawClient = rawClient;
  }

  async hello(request: EchoHelloRequest): Promise<EchoHelloResponse> {
    return await this.rawClient.fetch({}, "Echo/hello") as EchoHelloResponse
  }
}

export const buildEchoClient = (raw: IRawClient): IEchoClient => new EchoClient(raw);

export type EchoHelloRequest = {
    name: string;
};

export type EchoHelloResponse = {
    message: string;
};
```


---

- CodableToTypeScript
    - Swiftの型をTypeScriptの型に変換できる
- CallableKit
    - Swift protocolを任意の言語のinterfaceに変換できる

**→ WebAssembly × TypeScriptにも応用可能**

---


# WasmCallableKit

---

# WasmCallableKit

- Swift関数をWasmから呼び出せるクライアントから実行するためのスタブを生成

例:








