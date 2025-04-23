<!-- $theme: default -->

# DispatchQueue.sync するときのスレッド

----

## DispatchQueueでありがちなデッドロック

![](スクリーンショット%202018-10-29%201.40.21.png)

軽い気持ちで呼んだ関数が内部で `DispatchQueue.sync` を使っていた

----

## 便利関数が用意される

![](スクリーンショット%202018-10-29%201.43.55.png)

----

## これでクラッシュしない！

![](スクリーンショット%202018-10-29%201.44.46.png)

めでたしめでたし

----

## しかしここで疑問が

次のようなコードを実行するとき

![](スクリーンショット%202018-10-29%201.47.08.png)

----

![](スクリーンショット%202018-10-29%201.54.58.png)

----

## しかしここで疑問が

- 実際に実行するとクラッシュしない
- この場合 `Thread.isMainThread` は `true` を返す
- `myqueue` の中から呼んでいるのに、なぜ？
- (この時点で僕は勘違いをしています)

----

[apple/swift-corelibs-libdispatch](https://github.com/apple/swift-corelibs-libdispatch)

![](スクリーンショット%202018-10-29%202.00.58.png)

---- 

## デッドロックを発生させてエラーからソースをたどる
![](スクリーンショット%202018-10-29%202.04.58.png)


- `dispatch_sync called on queue already owned by current thread` というエラー文をswift-corelibs-libdispatchからgrep

  - → 出ない

---- 
- あった（`_dispatch_sync_wait`）

![](スクリーンショット%202018-10-29%202.07.44.png)

- C++の文字列リテラルは空白や改行があれば結合されるので、そこで分かれていた

----

## デッドロック判定処理をたどる

- `_dq_state_drain_locked_by` が判定しているっぽい

![](スクリーンショット%202018-10-29%202.11.12.png)

```C:lock.h
typedef uint32_t dispatch_tid;
typedef uint32_t dispatch_lock;
```

----


```
#define DLOCK_OWNER_MASK   ((dispatch_lock)0xfffffffc)
```

![](スクリーンショット%202018-10-29%202.13.12.png)

- C にありがちなビット演算
- `dq_state` と `tid` の下位3~32bitが同一かどうかで比較されてる
- `dq_state` は `DispatchQueue` が管理している値っぽいので、`tid` が何か分かれば良さそう

---- 

## _dispatch_sync_waitに戻る

![](スクリーンショット%202018-10-29%202.07.44.png)

- `tid` は `_dispatch_tid_self()` から来てるっぽい

----

## 

```
#define _dispatch_tid_self()  \
          ((dispatch_tid)_dispatch_thread_port())
```

```
#define _dispatch_thread_port()  \
       pthread_mach_thread_np(_dispatch_thread_self())
```

![](スクリーンショット%202018-10-29%202.22.54.png)

- ようやく見慣れた関数が出てくる (`pthread_self`)
- OSによって分岐しているが、実態はpthreadのスレッドID（あるいは同等にみなせる代物）っぽい


----

## _dispatch_sync_waitに戻る

![](スクリーンショット%202018-10-29%202.07.44.png)

- sync処理を行う対象のスレッドが現在のスレッドならデッドロックと判定しクラッシュさせている


----

## 最初の疑問に戻り、なぜrunOnMainThreadは問題なさそうなのか

----

![](スクリーンショット%202018-10-29%202.38.13.png)

----

## そもそもの勘違い

- `DispatchQueue` はそれぞれが専用のスレッドを持っていてその中でのみ動作するものだと思いこんでいた
  - これだとconcurrent queueは何者やねん！ってなる

----

### 最後に

- 事の発端となった `DispatchQueue.main.sync` だが、そもそもこれをしなきゃいけない場面はほぼないはず
- 適切に `DispatchQueue` （や、Lock）を使っていこう