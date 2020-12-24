# BGPd Multi Threading and Event Loop Architecture

## Structure `bgp_master`, `bgp`

`struct bgp_master` は bgpdのdaemon自体を管理する構造体だ.
threadmasterの構造体や, 全てのbgpインスタンス等などを包含する.
要するに一番大きなグローバル変数用の構造体だ.
簡単にメンバーを省略しつつ示す.

```cpp
struct bgp_master {
	struct list *bgp;
	struct thread_master *master;
	struct list *listen_sockets;
	uint16 port;
	struct labelpool labelpool;
	...
};
```

`struct bgp` は単一のbgpインスタンスを管理する構造体だ.
bgpdは複数のbgp instanceを管理できる. 例えば以下のようなconfig
でbgpdを動かした場合, bgpインスタンスの数は三つである.

```
router bgp 65001
 bgp router-id 1.1.1.1
 !
 segment-routing srv6
  locator loc0
 !
 address-family ipv4 vpn
 exit-address-family
!
router bgp 65001 vrf vrf10
 bgp router-id 1.1.1.1
 !
 address-family ipv4 unicast
  sid vpn export auto
	rt both 65001:10
 exit-address-family
!
router bgp 65001 vrf vrf20
 bgp router-id 1.1.1.1
 !
 address-family ipv4 unicast
  sid vpn export auto
	rt both 65001:20
 exit-address-family
!
```

## Function `main`

```cpp
int main()
{
	...
	bgp_init()
	...
	bgp_pthread_run()
	frr_run()
	return 0;
}

void bgp_init()
{
	...
	bgp_zebra_init(bm->master, instance);
	bgp_pthread_init();
	...
}
```

`bgp_init` で pthreadの初期化や, zclientの初期化等を行っている.
これをみるとわかる通り, bgpdの内部では, threadmaster以外に二つの
pthreadを起動していることがわかる. 要するに多分3multi threadingで
稼働しているはずである.

## default `thread_master` initialization

defaultのthreadmasterはどのように起動し始めるのかを整理する.
まず, `bgp_zebra_init`関数では, `bm->master` (default threadmaster) を使って
zclientの初期化を行う. 以下のように, zclientは threadmasterを引数に
して初期化を行っている.

```cpp
// bgpd/bgp_zebra.c

struct zclient *zclient;
void bgp_zebra_init(struct thread_master *m)
{
	zclient = zclient_new(m, ...);
	zclient_init(zclient, ZEBRA_ROUTE_BGP, ...);
	zclient->zebra_connected = ...;
	...
}
```

zclientの実態は関数ポインタの集合であり,
ZAPIによる通信に応じて登録した関数を呼び出すようになっている.
また `zclient_new` 関数では, zclientをmallocして初期化するだけ.

```cpp
struct zclient *zclient_new(struct thread_master* master)
{
	struct zclient *z;
	z = malloc(...)
	z->ibuf = stream_new(..)
	z->obuf = stream_new(..)
	z->master = master;
}
```

`zclient_init` 関数ではZAPIを実行するための
event task を設定している. こんな感じにzclientは自動で
connectしに行って, 可能ならばreadし続ける非同期event chain
に突入するようだ.
おそらく zserver との接続が切断されたあとも
`zclient_event(ZCLIENT_SCHEDULE)` を実行するだけで
再接続するように動かすことが可能だろう. よくできている.

```cpp
void zclient_init(zclient, ...)
{
	...
	zclient_event(ZCLIENT_SCHEDULE, zclient);
}

void zclient_event(enum event ev, struct zclient *zc)
{
	switch (ev) {
	case ZCLIENT_SCHEDULE:
		thread_add_event(zc->master, zclient_connect, zclient, ...);
		break;
	case ZCLIENT_CONNECT:
		thread_add_timer(zc->master, zclient_connect, zclient, ...);
		break;
	case ZCLIENT_READ:
		thread_add_read(zc->master, zclient_read, zclient, ...);
		break;
	}
}
```

## non-default `thread_master` initialization

defaultでないtaskの残り二つがどのように初期化されていくかを整理する.
以下にコードを省略して示す.

```cpp
struct frr_pthraed *bgp_pth_io;
struct frr_pthraed *bgp_pth_ka;
void bgp_pthreads_init()
{
	struct frr_pthread_attr io = {
		.start = frr_pthread_attr_default.start,
		.stop = frr_pthread_attr_default.stop,
	};
	struct frr_pthread_attr ka = {
		.start = bgp_keepalives_start,
		.stop = bgp_keepalives_stop,
	};
	bgp_pth_io = frr_pthread_new(&io, "BGP I/O thread", "bgpd_io");
	bgp_pth_ka = frr_pthread_new(&ka, "BGP Keepalives thread", "bgpd_ka");
}

void bgp_pthread_run()
{
	frr_pthread_run(bgp_pth_io, NULL);
	frr_pthread_run(bgp_pth_ka, NULL);
	frr_pthread_wait_running(bgp_pth_io);
	frr_pthread_wait_running(bgp_pth_ka);
}
```

`bgp_init` で pthreadの初期化や, zclientの初期化等を行っている.
これをみるとわかる通り, bgpdの内部では, threadmaster以外に二つの
pthreadを起動していることがわかる. 要するに多分3multi threadingで
稼働しているはずである.

### BGP I/O Thread

IO threadは `frr_pthread_atr_default` を利用しているが,
これは `lib/frr_pthread.c` にあらかじめ用意されたテンプレートだ.
これだけだと特に何もすることはないのだが, 多分この先, socketに対する
read/write の関数をこの thread に `thread_add_read` か何かで登録して
動かすのだろう. 名前の通りならば...
ひとまず IO thread は FRRのevent loopとして動作している.
`bgp_pth_io` グローバル変数は, `bgpd/bgp_io.c` で参照されていて,
ここで多分色々と event loop が設定されるんだろう.

### BGP Keepalives Thread

KA threadは, `bgp_keepalives_{start,stop}` で初期化されており,
このスレッドは event loop 方式ではなく動作しているようだ.
このthreadは多分bgp keepalive を peer ごとに定期的に送信するための
pthreadだと思う. (なんかこの辺で俺のバグが入っていてもおかしくはない...)
基本的には, pthread を生で使って, timeradd
で関数を呼び出していくようになっているみたいだ.

## Actual BGP instance execution

これはCLI起因なのだろう. CLIで設定された瞬間に必要に応じて
event loopにtaskを登録するはずだ.

### Creating BGP instance

多分CLIにconfigが投入されると巡り巡って, `bgp_create()`関数が
呼び出されるはずである. なので`bgp_create`を起点にどのように
BGPのインスタンスのthreadingが行われるかを整理する.

```
struct bgp *bgp_create(...)
{
	struct bgp *bgp = malloc(...);
	...
	bgp_lock(bgp);
	bgp_process_queue_init(bgp);
	...
	bgp->peer = list_new();
	...
	FOREACH_AFI_SAFI(afi, safi) {
		bgp->route[afi, safi]     = bgp_table_init(bgp, afi, safi);
		bgp->aggregate[afi, safi] = bgp_table_init(bgp, afi, safi);
		bgp->rib[afi, safi]       = bgp_table_init(bgp, afi, safi);
		...
	}
	...
	update_bgp_group_init(bgp);
	...
	return bgp;
}
```

`bgp_process_queue_init` 関数では, `bgp->process_queue` の初期化をする.
以下の `work_queue_new`関数で生成される work-queueは `frr/lib` 配下にある
work-queueフレームワークである.

```
extern struct bgp_master bm;
...
void bgp_process_queue_init(struct bgp *bgp)
{
	if (!bgp->process_queue) {
		bgp->process_queue = work_queue_new(bm->master, ...)
	}
}
```

### BGP Passive connection
### BGP Active connection
