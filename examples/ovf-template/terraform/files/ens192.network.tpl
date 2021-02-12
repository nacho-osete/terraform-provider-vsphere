[connection]
id=ens192
type=ethernet
interface-name=ens192

[ipv4]
address1=${address}/${mask},${gateway}
dns=${dns};
dns-search=
may-fail=false
method=manual
