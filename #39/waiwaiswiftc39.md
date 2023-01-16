---
marp: true
paginate: true
size: 16:9
---

## わいわいswiftc #39

# Swiftの型をTypeScriptで表す

Twitter @iceman5499

<!-- _footer: 2023年1月20日 -->

---

Swiftにおけるファントムタイプの意味論がTypeScriptにおいて再現できていない #53
https://github.com/omochi/CodableToTypeScript/issues/53
の内容

-- 背景・目的

Swiftは良い言語
いろんなところで使いたい
サーバサイドではフルパワーで使える
Webで良い感じに使うためにはTypeScriptとうまく連携する必要がある
→ Swiftの型をTypeScriptで表したい


# 基本的な型の変換

わいわいswiftc #35で紹介しました

<簡単な復習>
<変換例>

今回はその延長線の話です

# Swiftの型とTypeScriptの型の違い

Swiftはnominal typing
TypeScriptはstructual typing

<Swiftでは区別されるけど、TypeScriptだと区別されない例>
```swift
struct User: Codable {
    var id: String
    var name: String
}
struct Pet: Codable {
    var id: String
    var name: String
}
```

```ts
export type User = {
    id: string;
    name: string;
};
export type Pet = {
    id: string;
    name: string;
};

function useUser(user: User) {}
function usePet(pet: Pet) {
    useUser(pet); // ← petがUserとして使えてしまう
}
``` 

これはそういう仕様なのである程度はしょうがない。

# ファントムタイプを再現したい

<Swiftでよく使うファントムタイプの例>
```swift
struct GenericID<T>: RawRepresentable { var rawValue: String }
typealias UserID = GenericID<User>
typealias PetID = GenericID<Pet>
```

<TSに変換した例>
```ts
type GenericID<T> = string;
type UserID = GenericID<User>; // string型
type PetID = GenericID<Pet>; // string型

function makePetDetailLink(petID: PetID) {
    return `/pet/${petID.rawValue}/detail`;
}
const user: User = ...;
makePetDetailLink(user.id); // OK😅
```

# ファントムタイプを再現したい

TypeScriptでファントムタイプを再現する例

```ts
type UserID = string & {
	User: never;
};
type PetID = string & {
	Pet: never;
};

function useUserID(userID: UserID) {
}
const petID = {} as PetID;
useUserID(petID); // Property 'User' is missing in type 'PetID'
```

# ジェネリックな場合に対応できない

先程のファントムタイプをより一般化し、
`type UserID = GenericID<User>;` と記載できるようにしたい。

```ts
// こういう感じにしたい
type GenericID<T> = string & {
	[Tの名前]: never; 
};
```

ダメな例

```ts
type GenericID<T extends string> = string & {
	T: never; 
};
type User = { ... } & "User";
type UserID = GenericID<User> // string & { T: never; }
```

TのString Literal Type部分を取り出せてないのでTということになってしまう
また`User`の型が自然に生成できない形になって不便。
（`{ ... } & "foo"`という式は書けないので`as`が必要になる）

型のメタタグを専用プロパティに保持すると解決する

```ts
// Conditional Typeとinfer演算子を用いた例
type GenericID<T> = string & { $tag?: "GenericID" } & (
	T extends { $tag?: infer TAG } 
		? { $0?: TAG; }
		: {}
);

type User = { ... } & {
	$tag?: "User";
};
type UserID = GenericID<User>; // string & { $0?: "User"; }

// テスト
type Pet = { } & { $tag?: "Pet" };
type PetID = GenericID<Pet>;
function useUserID(userID: UserID) {}
const petID = {} as PetID;
useUserID(petID); // Type '"Pet"' is not assignable to type '"User"'.
```

ちょっと一般化して専用の型を作る。

```ts
type TagRecord<TAG extends string> = { $tag?: TAG };
type NestedTag0<Child> = Child extends TagRecord<infer TAG>
	? { $0?: TAG; }
	: {};
```

全ての型に `TagRecord<T>` をつけ、ジェネリックパラメータを持つ型には追加で`NestegTagX<T>`をつけていけば、nominal typingを再現できる。

```ts
type GenericID<T> = string & TagRecord<"GenericID"> & NestedTag0<T>;

type User<Domain> = {
  id: GenericID<User<Domain>>;
  name: string
} & TagRecord<"User"> & NestedTag0<Domain>;

type Server = {} & TagRecord<"Server">;
type Client = {} & TagRecord<"Client">;
type ServerUser = User<Server>;
type ClientUser = User<Client>;

function useServerUser(user: ServerUser) {}
const clientUser = {} as ClientUser;
useServerUser(clientUser); // Type '"Client"' is not assignable to type '"Server"'. 👍
```

ただし微妙な抜け穴もある

```ts
function useServerUserID(id: GenericID<ServerUser>) {}
useServerUserID(clientUser.id); // OK 😢
```

`GenericID<ServerUser>` は `string & { $tag?: "GenericID" } & { $0?: "User" }` であり、`Server`のタグが抜け落ちてしまっている。

→ `TagRecord<T>` の時点で再帰的にTのジェネリックパラメータが持つタグも拾っておく必要がある。

```ts
type TagOf<Type> = Type extends { $tag?: infer TAG } ? TAG : never;
type TagRecord0<T extends string> = {
	$tag?: T
};
type TagRecord1<T extends string, C0> = {
	$tag?: T & {
	  $arg0?: TagOf<C0>;
  };
};
type TagRecord2<T extends string, C0, C1> = {
	$tag?: T & {
	  $arg0?: TagOf<C0>;
	  $arg1?: TagOf<C1>;
	};
}; // ...

type GenericID<T> = string & TagRecord1<"GenericID", T>;

type User<Domain> = {
  id: GenericID<User<Domain>>;
  name: string
} & TagRecord1<"User", Domain>;

type Server = {} & TagRecord0<"Server">;
type Client = {} & TagRecord0<"Client">;
type ServerUser = User<Server>;
type ClientUser = User<Client>;

function useServerUser(user: ServerUser) {}
const clientUser = {} as ClientUser;
useServerUser(clientUser); // Type '"Client"' is not assignable to type '"Server"'. 👍
function useServerUserID(id: GenericID<ServerUser>) {}
useServerUserID(clientUser.id); // Type '("User" & { $arg0?: "Client" })' is not assignable to type '("User" & { $arg0?: "Server"; })'.👍

// 展開するとこう
type ServerUserID = GenericID<ServerUser>; // string & { $tag?: "GenericID" & { $arg0?: "User" & { $arg0?: "Server" } } }
```

`TagRecordX`を使うことで型パラ分のタグが事前に展開され、その展開済みのタグを`TagOf`で拾う。

これでかなりいい感じになってきた。

`TagRecord0`、`TagRecord1`、`TagRecord2` と型パラの数だけ`TagRecord`が必要になってしまうのが微妙なので、これも改善する。
Mapped TypeとTuple Typeを組み合わせて、型引数を計算する。

```ts
type TagOf<Type> = Type extends { $tag?: infer TAG } ? TAG : never;

type TagRecord<T extends string, Args extends any[] = []> = Args["length"] extends 0
  ? {
    $tag?: T
  } : {
    $tag?: T & {
      [I in keyof Args]: TagOf<Args[I]>
    }
  };
  
type ServerUserID = GenericID<ServerUser>; // string & { $tag?: "GenericID" & ["User" & ["Server"]] }
```

Swiftから変換する型全てに`TagRecord`をつけておけば、nominal typingが実現できる。

しかし、Swiftから変換するときにTypeScriptネイティブなジェネリック型に変換されるケースが少なからず存在する。

| Swift | TypeScript |
| --- | --- |
| `[T]` | `T[]` | 
| `T?` | `T | null` |
| `[String: T]` | `Map<string, T>` |

これらについては、数が限られるので個別に対応した。

```ts
type TagOf<Type> = Type extends TagRecord<infer TAG>
    ? TAG
    : null extends Type
        ? "Optional" & TagOf<Exclude<Type, null>>
        : Type extends (infer E)[]
            ? "Array" & TagOf<E>
            : Type extends Map<string, infer V>
                ? "Dictionary" & TagOf<V>
                : never;
```




---

# おわり
