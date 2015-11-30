/**
 * class to define the failover ip
 */
define kvmvirsh::guest::failoverip(
    $netid		= undef,
    $intip		= undef,

	$extif		= "eth0",
    $failoverip	= undef,
    $failovernm	= "255.255.255.252",

    $tcpports	= "80,443",
	$udpports	= undef,

	$autostart	= "yes",		# yes or no
) {

	$scriptname = "/etc/firewall/980-${name}-${failoverip}.sh"

	if $autostart == 'yes' {
	    $notifyreload = Exec["failover_${name}-${failoverip}_restart"]
	} else {
	    $notifyreload = []
	}

	file{"${scriptname}":
	    mode => "0550",
		content => template("kvmvirsh/firewall/failoverip.sh.erb"),
		require	=> File["/etc/firewall/"],
		notify	=> $notifyreload,
	}

	exec{"failover_${name}-${failoverip}_restart":
	    command => "${scriptname} restart",
	    refreshonly => true
	}
}
