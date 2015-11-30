/**
 * creates a virtual network between the hosts
 *
 */
define kvmvirsh::network::vlan (
  $remoteip = undef,
  $rhostid = undef,
  $rnetwork = "192.168.1${rhostid}.0/24",
  $lnetwork = "${::kvmvirsh::network::network}",
) {

	if $remoteip != $::ipaddress_eth0 {
		if $remoteip > $::network_eth0 {
			$localvip  = "192.168.2$rhostid.1"
			$remotevip = "192.168.2$rhostid.2"
		} else {
			$localvip  = "192.168.2$rhostid.2"
			$remotevip = "192.168.2$rhostid.1"
  		}

		file {"/etc/firewall/011-init-${name}.sh":
			ensure  => present,
			owner   => "root",
			group   => "root",
			mode    => "0550",
			content => template("kvmvirsh/firewall/init-vlan.sh.erb"),
			require => File["/etc/firewall"]
		}
	} else {
		file {"/etc/firewall/011-init-${name}.sh":
			ensure 	=> absent,
      	}
	}
}
