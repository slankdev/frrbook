# BGPd Multi Threading and Event Loop Architecture

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
	bgp_pthread_init()
	...
}

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
