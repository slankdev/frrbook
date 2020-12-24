
# Daemon Startup

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

### Function `frr_preinit`

まず `frr_preinit` を呼び出すことでFRR上でのデーモン情報を初期化する.
FRRのデーモンは共通して, config, backup-config, running-config vty-port番号,
protocol番号, logger, yang-tree 等々の情報を持つが, それらの情報は
`struct frr_daemon_info` に記録されている.
新しく daemon を追加しようとする開発者でなければ,
基本的にはこの構造体を理解する必要はないと思われる.

その後, `bgp_master_init()`, `bgp_error_init()` 等のbgpd固有の初期化関数を
実行する. この部分はそれぞれのdaemonごとに固有の処理を行うため, 今は
強く意識する必要はない.

### Function `frr_init`

`frr_init` 関数は, `struct thread_master*` を返す.
それぞれの daemon はこの threadmasterを用いて非同期イベントループを
ぶん回す.

これだけなら簡単だが, BGPdとかはベットでpthreadもつかったりしているので
すごく複雑になっているようにみえる.

### Function `frr_config_fork`

そして `frr_config_fork()` を実行する.
このタイミングでdaemonは必要に応じて daemonize fork をしたりする.
daemonize 処理のタイミングでSignalハンドラの処理等も色々と行う.
FRRのdeamonはこの辺をかなりwrapした実装になっているので, Signal処理や
TTY周りなどで不可解に感じたらこの辺をよく読んでみると良い.

このタイミングに loggerの初期化もしているはず.
詳しくはここにも書いてある.
http://docs.frrouting.org/projects/dev-guide/en/latest/logging.html

### Function `frr_run`

最後に `frr_run()` を実行して, これで初めて FRR のdaemonの起動が開始する.
`frr_run` は内部で, VTYの起動を行う, libfrr の multi threading framework
を開始させる. multi threading framework の開始部分を簡単に省略すると
以下のようになっている.

```cpp
voi frr_run(struct thread_master *master)
{
	frr_vty_serv();
  ...
	struct thread thread;
	while (thread_fetch(master, &thread))
		thread_call(&thread)
}
```

FRRのMulti thread frameworkは Event駆動型のMulti Thread Frameworkであり,
それぞれのEventごとにいthreadを起動させることができる.

## Multi Thread Framework

Multi Thread Frameworkに関してのより詳しい説明は以下に示されている.
[Process Architecture](http://docs.frrouting.org/projects/dev-guide/en/latest/process-architecture.html#)


ここからは *thread*, *threadmaster* という用語を用いて構造を簡単に整理する.
この *thread* は libeventでいう Event または Task のことを示す.
公式docいわく, threadmaster はそのまま threadmaster と読んで, thread のことを
task と読んでいるようなのでそうやって説明する.

多分 thread という単位でたくさんの処理をイベントごとに登録することができて,
それが実態になった物のことを task と読んでいるんだと理解している.

threadmaster は [`struct thread_master`](https://github.com/FRRouting/frr/blob/7c08b70a533627c2dee0df28ea9111818fd541d0/lib/thread.h#L70) で表現されている.
この構造体は, global state objectで, thread のコンテキスト等を保持している.
それぞれのdaemon ごとに一つの threadmaster が存在している.

Daemonの起動時には小さな task を設定し, それが起因してたくさんの複雑な処理が
開始し始めるようになっている. 以下にtaskの種類を示す

| name | description |
| :----: | :-- |
|`THREAD_READ`    | ファイル記述子が読み取り可能になるのを待ってから実行する |
|`THREAD_WIRTE`   | ファイル記述子が書き込み可能になるのを待ってから実行する |
|`THREAD_TIMER`   | スケジュールされてから一定時間が経過した後に実行される |
|`THREAD_EVENT`   | 何かしらのイベント起因で実行される, Event自体のタイプとセット起動する物だと理解している. たとえば bgpd は FSM(Finite State Model)のフレームワークの上に実装されているけど, それぞれのイベントごとに実行されるtaskはこのtypeで表現されている(はず). Event Typeはintで表現されている. |
|`THREAD_READY`   | レディキューのタスクに内部的に使用されるタイプ(まったくわかっていない) |
|`THREAD_UNUSED`  | 意味不明j |
|`THREAD_EXECUTE` | 実行中を表すタイプ. 実行されるタスクは全てこのtypeに実行直前に書き換えられる. |

例えば tcpのecho server を複数のclientに対して実施しようとした時.
server-fd (listening socket) と accepted-fd (client peer socket) の二種類が存在する.
このようなケースの時, それぞれの eventごとに非同期にうまく並行処理をしたい時はい可能のように書くはず.

```cpp
struct thread_masgter m;

int client_send_func(void *)
{
  int ret = write(client_fd, buf, buflen)
	return ret;
}

int client_read_func(void *)
{
  int ret = read(client_fd, buf, sizeof(buf));
	if (ret < 0) {
		return -1;
	}
	thread_add_write(m, client_send_func, NULL, client_fd, NULL);
	return 0;
}

int listen_func(void *)
{
  int client_fd = accept()
	thread_add_read(m, client_read_func, NULL, client_fd, NULL);
	return 0;
}

int main()
{
  listen_fd = socket()

	struct thread th;
	thread_add_read(m, listen_func, NULL, listen_fd, NULL);
	while (thread_fetch(m, &th))
		thread_call(&th)
}
```

このようにして全てのdaemonはうまい具合の非同期なevent loopのうえで素晴らしい
routing protocolを動かしているっぽい...
