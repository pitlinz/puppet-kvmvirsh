/**
 * @see http://kovyrin.net/2006/04/05/connecting-two-remote-local-networks-with-transparent-bridging/
 */
define kvmvirsh::network::vtun(
	$ensure	= present,
  	$remoteip = undef,
	$rhostid = undef,
	$rnetwork = "192.168.1${rhostid}.0/24",
	$lnetwork = "${::kvmvirsh::network::network}",
	$ipfwdtbl = 'KVMVLAN', # table that holds
) {
	if !defined(Package["vtun"]) {
	    package{"vtun":
	        ensure => latest
		}
	}
}
