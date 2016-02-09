/**
 * class to register the client at cloudflaire DNS
 *
 */
class kvmvirsh::guest::cloudflaire(
    $email 	= "",
	$apikey = "",
	$zoneid	= "",
) {
	if !defined(Package["curl"]) {
	    package{"curl":
	        ensure => latest,
	    }
	}

	file {"/etc/libvirt/kvmvirsh/cloudflaire":
	    ensure => directory,
	}
}

define kvmvirsh::guest::cloudfaire::dnsentry(
    $ip		= undef,
	$email 	= $::kvmvirsh::guest::cloudflaire::email,
	$apikey	= $::kvmvirsh::guest::cloudflaire::apikey,
	$zoneid	= $::kvmvirsh::guest::cloudflaire::zoneid,
) {
    if is_ip_address($ip) {
        exec{"cfapi_${name}":

		}
    }
}
