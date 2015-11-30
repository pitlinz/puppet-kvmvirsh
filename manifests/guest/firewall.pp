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

	include ::kvmvirsh::firewall

    file{"/etc/firewall/910-${name}.sh":
        mode 	=> '0550',
		content => template("kvmvirsh/firewall/guest.sh.erb"),
		require => File["/etc/firewall"],
		notify 	=> Exec["fw_restart_910-${name}"],
    }

    exec{"fw_restart_910-${name}":
        command => "/etc/firewall/910-${name}.sh restart",
        refreshonly => true,
	}
}
