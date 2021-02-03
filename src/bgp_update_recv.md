
## BGPで経路を受け取る時

- `bgp_process_packet` からそれぞれのBGP Messageの解析が始まる.
- 基本的に `bgp_update_receive` 関数を起点に読み進めると良い
  - `bgp_process_packet`
		- `bgp_update_receive`
			- `bgp_attr_parse`
				- `bgp_attr_prefix_sid`

```
bgp_process_packet()
{
	while {
	  switch msg.type {
		case OPEN:
		  ...
	  case UPDATE:
		  bgp_update_receive()
		}
	}
}

bgp_update_receive()
{
  //parse1

	if (attribute_len) {
		bgp_attr_parse()
	}


	for () {
	  switch (i) {
		case NLRI_UPDATE:
		case NLRI_MP_UPDATE:
		  bgp_nlri_parse(withdraw=0):
		  break;
		case NLRI_WITHDRAW:
		case NLRI_MP_WITHDRAW:
		  bgp_nlri_parse(withdraw=1):
		  break;
		}
	}


}

bgp_nlri_parse(safi, withdraw)
{
  switch safi {
	case SAFI_UCAST:
	case SAFI_MCAST:
		return bgp_nlri_parse_ip()
	case SAFI_VPN:
		return bgp_nlri_parse_vpn()
	}
}

bgp_nlri_parse_vpn()
{
  // parse label
  // parse RD
	// parse prefix

	while (stream_readable) {
	  if (attr) {
		  bgp_update()
		} else {
		  bgp_withdraw()
		}
	}
}

bgp_update()
{
  // これがクッソ長い...
}

bgp_attr_parse()
{
  for attr in attrs {
		switch attr.type {
		case PREFIX_SID
			bgp_attr_prefix_sid(attr)
		}
	}
}

bgp_attr_prefix_sid()
{
}
```

## Best Path Selection

以下のdebug commandで debug logを確認することができるようになる.
運用時は適宜 prefix を絞って実施するべし.
```
debug bgp 0::/0
```

まずBGPのRIBに対しての認識を整理する必要がある.
BGP RIBは以下のような状態を持っている

(とりあえず以下は適当に書いている)
```
struct bgp_rib_entry {
  uint16_t flag;
#define FLAG_RIB_VALID
#define FLAG_RIB_BESTPATH
};
```
