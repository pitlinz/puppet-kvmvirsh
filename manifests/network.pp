/**
 * class to configure default network
 *
 * this network is used for bridged mode
 *
 * @see http://lukas.zapletalovi.com/2013/04/managing-many-servers-with-foreman.html
 * @see https://github.com/thias/puppet-libvirt/blob/master/manifests/network.pp
 *
 */
class kvmvirsh::network (
    $forward_dev	= 'eth0',
	$forward_mode 	= 'route',
    $net_id			= $::kvmvirsh::hostid,
	$dhcp			= {
	    	'start'	=> 9,
	    	'end'	=> 99,
		}
) {
    # ----------------------------------------------
    # includes
    # ----------------------------------------------

    include ::kvmvirsh
    include ::kvmvirsh::firewall

    # ----------------------------------------------
    # declarations
    # ----------------------------------------------

	$xmlpath = "${::kvmvirsh::xmlpath}/networks"

	# mac address of type x2:xx:..,x6:xx:..,xA:xx:..,xE:xx:...
	# are Locally Administered Address Ranges that can be used on your network without fear of conflict
    if $net_id < 10 {
        $int_net_id = $net_id * 1
		$macaddrpre = "02:01:0a:0e:0${int_net_id}:"

		$arrippre = split("${::kvmvirsh::ipprefix}","\.")
		if $arrippre[2] < 10 {
			$network 	= "${::kvmvirsh::ipprefix}0${int_net_id}.0/24"
			$ipaddrpre 	= "${::kvmvirsh::ipprefix}0${int_net_id}"
		} else {
			$network 	= "${::kvmvirsh::ipprefix}${int_net_id}.0/24"
			$ipaddrpre 	= "${::kvmvirsh::ipprefix}${int_net_id}"
		}
	} else {
		$macaddrpre = "02:01:0a:0e:${net_id}:"
		$network 	= "${::kvmvirsh::ipprefix}${net_id}.0/24"
		$ipaddrpre 	= "${::kvmvirsh::ipprefix}${net_id}"
	}

    # ----------------------------------------------
    # main
    # ----------------------------------------------

    # ----------------------------------------------
    # main
    # ----------------------------------------------

	if !defined(File["${xmlpath}"]) {
		file {"${xmlpath}":
			ensure 	=> directory,
			require => File["${::kvmvirsh::xmlpath}"],
		}
	}

	if is_hash($dhcp) {
	    $vnetdhcp = {
	        start 	=> "${ipaddrpre}.${dhcp[start]}",
	        end		=> "${ipaddrpre}.${dhcp[end]}",
	    }
	} else {
	    $vnetdhcp = undef
	}

	::kvmvirsh::network::vnet{"default":
	    ensure 			=> running,
	    autostart		=> true,
	    bridge			=> $::kvmvirsh::bridgename,
	    forward_mode	=> $forward_mode,
	    forward_interfaces => ['eth0'],
	    forward_dev		=> $forward_dev,
	    ip				=>
	        {
	        	'address'	=> "${ipaddrpre}.1",
				'netmask'	=> "255.255.255.0",
				'dhcp'		=> $vnetdhcp
	    	}
		,
		virtnet			=> $network,
		mac				=> "${macaddrpre}01",
	}

}
