
# BGPd RFAPI

## VNC (Virtual Network Control) & RFP (Remote Forwarder Procotol)

[VNC and VNC-GW](http://docs.frrouting.org/en/latest/vnc.html) は
FRRにだいぶまえから実装されている, オレオレSD-WAN機能みたいな物だと
理解している. ただしいかわからない.
この機能のせいで死ぬほど色々と複雑になっている...
rfapi == rfp api という認識で問題ないだろう.

ちなみにこれらの機能は綺麗にEVPNによって回収されるような機能セットだと
認識しており, そのうちなくなるのかもしれない..?
そもそもBGP VPNの非標準化versionにしか見えない... おれの理解が間違っている..!?

## source code

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
