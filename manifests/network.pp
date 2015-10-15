/**
 * class to configure main bridge
 *
 * @see https://github.com/thias/puppet-libvirt/blob/master/manifests/network.pp
 *
 */
class kvmvirsh::network (
    $ext_if			= 'eth0',
	$forward_mode 	= 'route',

) {
    # ----------------------------------------------
    # includes
    # ----------------------------------------------

    include ::kvmvirsh

    # ----------------------------------------------
    # declarations
    # ----------------------------------------------

	$xmlpath = "${::kvmvirsh::xmlpath}/networks"

	# mac address of type x2:xx:..,x6:xx:..,xA:xx:..,xE:xx:...
	# are Locally Administered Address Ranges that can be used on your network without fear of conflict
    if ($::kvmvirsh::hostid < 10) {
		$macaddrpre  = "02:06:0a:0e:0${::kvmvirsh::hostid}:"
	} else {
		$macaddrpre  = "02:06:0a:0e:${::kvmvirsh::hostid}:"
	}

    # ----------------------------------------------
    # main
    # ----------------------------------------------

	file {"${xmlpath}":
		ensure 	=> directory,
		require => File["${::kvmvirsh::xmlpath}"],
	}

	::kvmvirsh::network::vnet{"default":
	    ensure 			=> running,
	    autostart		=> true,
	    forward_mode	=> $forward_mode,
	    ip				=> [
	        {
	        	'address'	=> "${::kvmvirsh::ipprefix}${::kvmvirsh::hostid}.1",
				'netmask'	=> "255.255.255.0"
	    	}
		],
	}

}
