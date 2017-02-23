/**
 * class to configure bind dns server
 */
class kvmvirsh::binddns(
    $listen	= $::ipaddress_virbr0,
	$servicename = "bind9"
) {
    if !defined(Package["bind9"]) {
        package{"bind9":
            ensure => latest
		}
    }

    if !defined(Service["${servicename}"]) {
        service{"${servicename}":
            ensure => running,
            require => Package["bind9"],
		}
    }

}
