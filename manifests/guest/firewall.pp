/**
 * generate guest firewall script
 *
 */
define kvmvirsh::guest::firewall(
    $intip	 	= undef,
    $extip	 	= $::ipaddress,
    $sshport 	= undef,
	$tcpports	= undef,
	$fwnat		= [],
	$fwfilter	= [],
) {
	# notify{"firewall ${name} TCP: ${tcpports}":}

	include ::kvmvirsh::firewall

	# notify {$tcpports:}

    file{"/etc/firewall/910-${name}.sh":
        mode 	=> '0550',
		content => template("kvmvirsh/firewall/guest.sh.erb"),
		require => File["/etc/firewall"],
		notify 	=> Service["firewall"],
    }
}
