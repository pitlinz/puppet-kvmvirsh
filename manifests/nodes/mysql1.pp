/**
 * class to define a mysql node
 */
class kvmvirsh::nodes::mysql1(
    $nodename	  = "",

	$ensure       = present,
	$autostart    = true,
    $nodeid       = 10,

    $extip		  = "${::ipaddress}",

	$cpus		= "2",
	$memory		= "8192",

	$datasize	= "20G",
	$logsize	= "50G",


    $installurl	= "http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/",
) {

	include ::kvmvirsh::network

	if $nodename == undef {
	    fail ("no nodename defined for mysql in w4c_hosts::virshnodes::mysql on node ${::fqdn}.")
	}

	# os disk
	$hda		= {
	    vgname 	=> $::kvmvirsh::pool0,
		size	=> '10G',
	}
	# swap disk
	if $memory < 16000 {
	    $_swapsize = floor($memory/1000)
	} else {
	    $_swapsize = 8
	}

	$hdb		= {
	    vgname 	=> $::kvmvirsh::pool0,
		size	=> "${_swapsize}G",
	}
	# mysql data disk
	$hdc		= {
	    vgname 	=> $::kvmvirsh::pool0,
		size	=> $datasize,
	}
	# mysql log disk
	$hdd		= {
	    vgname 	=> $::kvmvirsh::pool0,
		size	=> $logsize,
	}

	$intip = "${::kvmvirsh::network::ipaddrpre}.${nodeid}"

	::kvmvirsh::guest{"${nodename}":
		autostart 	=> true,
	  	vncid		=> $nodeid,
		guestcpus 	=> $cpus,
		guestmemory => $memory,
		guestintip	=> $intip,

		hda			=> $hda,
		hdb			=> $hdb,
		hdc			=> $hdc,
		hdd			=> $hdd,

		fwnat		=> ["PREROUTING -p TCP --dport 3306 -d ${::ipaddress} -j DNAT --to-destination ${intip}"],

		installurl	=> $installurl,
	}
}
