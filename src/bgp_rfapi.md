
## BGPd RFAPI

- `bgpd/rfapi/rfapi.c`

```
bgp_update()
{
  ...

  if SAFI == SAFI_MPLS_VPN {
    rfapiProcessUpdate()
	}

  ...
}

rfapiProcessUpdate()
{
  ...

  if safi == SAFI_MPLS_VPN {
		rfapiBgpInfoFilteredImportVPN()
	}
}

rfapiBgpInfoFilteredImportVPN()
{
}
```
