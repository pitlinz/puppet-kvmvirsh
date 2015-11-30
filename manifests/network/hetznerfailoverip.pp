/**
 * creates a bash script to move the failover ip to the current host
 */
define kvmvirsh::network::hetznerfailoverip(
    $user 		= undef,
    $pwd		= undef,
    $failoverip	= undef,
    $hostip		= $::ipaddress,
) {
    if !defined(Package["curl"]) {
        package{"curl":
            ensure => latest
		}
    }

    file{"/usr/local/bin/hetznerfailoverip.sh":
        mode => '0550',
		content => template("kvmvirsh/scripts/hetznerfailover.sh.erb")
	}

}
