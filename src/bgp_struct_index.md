
## BGP Structure Index

### `struct bgp_nexthop_cache`

- definition: https://github.com/FRRouting/frr/blob/master/bgpd/bgp_nexthop.h
- `NH_VALID` かどうか, だったり, `LABELED_VALID` みたいな要素が保存されている.
- CHANGED みたいな flagがあって, それが0な間は
  キャッシュとして動作するようになっている.
