/**
 * class to register the client at cloudflare DNS
 *
 */
class kvmvirsh::guest::cloudflare(
    $email 	= undef,
	$apikey = undef,
	$zoneid	= undef,
) {
	if !defined(Package["curl"]) {
	    package{"curl":
	        ensure => latest,
	    }
	}

	file {"/etc/libvirt/kvmvirsh/cloudflare":
	    ensure => directory,
	}

	if !defined(Package["jshon"]) {
	    package{"jshon":
	        ensure => latest,
		}
	}

	file {"/etc/libvirt/kvmvirsh/cloudflare/getzoneid.sh":
	    content => template('kvmvirsh/cloudflare/getzoneid.sh.erb'),
	    require	=> File["/etc/libvirt/kvmvirsh/cloudflare"],
	    mode	=> "500",
	}
}

define kvmvirsh::guest::cloudflare::dnsentry(
    $ip		= undef,
	$email 	= $::kvmvirsh::guest::cloudflaire::email,
	$apikey	= $::kvmvirsh::guest::cloudflaire::apikey,
	$zoneid	= $::kvmvirsh::guest::cloudflaire::zoneid,
) {


    if is_ip_address($ip)  {

    }
}
