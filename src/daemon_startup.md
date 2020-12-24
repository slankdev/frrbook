
## Daemon Startup

FRRではzebra, bgpd, isisd, etc.. 等のたくさんのデーモンが稼働する.
これらのdaemonは frr/lib 配下に存在する共通のフレームワークを利用して
動作する. 要するに ospfd も isisd も実際はほとんど同じような起動方法
を行うことになっている. このchapterではその内容に関して整理する.

まずbgpdの起動方法をそれぞれみてみることにしよう.
BGPは実際はpthreadを用いてmulti threadモデルで動作しているため
詳しい方式に関しては後ほど詳しく説明する.
bgpdの起動の流れ(main関数)を簡単にしめす.

```cpp:bgpd/bgp_main.c
#include <zebra.h>
...
extern struct bgp_master *bm;
static struct frr_daemon_info bgpd_di;
...
int main(int argc, char **argv)
{
  ...
  frr_preinit(&bgpd_di, argc, argv)
	frr_opt_add(...)
	while (1) {
	  //parse opt
	}
  ...

	bgp_master_init(frr_init(), buffer_size)
	bgp_error_init()
	bgp_vrf_init()
	...
	bgp_init(instance)
	...
	frr_config_fork()
	bgp_gr_apply_running_config()
	bgp_pthreads_run()
	frr_run(bm->master)
}
```

まず `frr_preinit` を呼び出すことでFRR上でのデーモン情報を初期化する.
FRRのデーモンは共通して, config, backup-config, running-config vty-port番号,
protocol番号, logger, yang-tree 等々の情報を持つが, それらの情報は
`struct frr_daemon_info` に記録されている.
新しく daemon を追加しようとする開発者でなければ,
基本的にはこの構造体を理解する必要はないと思われる.

その後, `bgp_master_init()`, `bgp_error_init()` 等のbgpd固有の初期化関数を
実行する. この部分はそれぞれのdaemonごとに固有の処理を行うため, 今は
強く意識する必要はない.

そして `frr_config_fork()` を実行する.
このタイミングでdaemonは必要に応じて daemonize fork をしたりする.
daemonize 処理のタイミングでSignalハンドラの処理等も色々と行う.
FRRのdeamonはこの辺をかなりwrapした実装になっているので, Signal処理や
TTY周りなどで不可解に感じたらこの辺をよく読んでみると良い.

このタイミングに loggerの初期化もしているはず.
詳しくはここにも書いてある.
http://docs.frrouting.org/projects/dev-guide/en/latest/logging.html

