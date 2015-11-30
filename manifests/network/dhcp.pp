/**
 * install dhcp server
 */
class kvmvirsh::network::dhcp(
  $options    = '',
  $interfaces = 'virbr1',
) {
	case $::operatingsystem {
    	ubuntu, debian: {
      		$package_name = 'isc-dhcp-server'
    	}
    	default: {
      		fail("Unsupported operating system ${::operatingsystem}")
    	}
	}

  	package { $package_name:
    	ensure => installed,
  	}


}
