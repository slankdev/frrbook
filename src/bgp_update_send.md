
## BGPで経路を受け取る時

- 基本的に `bgp_update_receive` 関数を起点に読み進めると良い
	- `bgp_update_receive`
		- `bgp_attr_parse`
			- `bgp_attr_prefix_sid`

```
bgp_update_receive()
{
	if (attr_len) {
		bgp_attr_parse()
	}
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
