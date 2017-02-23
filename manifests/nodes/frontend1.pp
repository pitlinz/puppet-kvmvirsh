/**
 * class to define a frontend node
 */
class kvmvirsh::nodes::frontend1(
    $nodename	  = "",

	$ensure       = present,
	$autostart    = true,
    $nodeid       = 20,

    $extip		  = "${::ipaddress}",
	$tcpports	  = "80,443",
	$fwnat        = [],
	$fwfilter     = [],

	$cpus		= "1",
	$memory		= "4096",

	$disksize	= "50G",

    $installurl	= "http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/",
) {

	include ::kvmvirsh::network

	if $nodename == undef {
	    fail ("no nodename defined for mysql in w4c_hosts::virshnodes::mysql on node ${::fqdn}.")
	}

	# os disk
	$hda		= {
	    vgname 	=> $::kvmvirsh::pool0,
		size	=> $disksize
	}


	$intip = "${::kvmvirsh::network::ipaddrpre}.${nodeid}"

	::kvmvirsh::guest{"${nodename}":
		autostart 	=> true,
	  	vncid		=> $nodeid,
		guestcpus 	=> $cpus,
		guestmemory => $memory,
		guestextip	=> $extip,
		guestintip	=> $intip,

		hda			=> $hda,

		tcpports	=> $tcpports,
		fwnat       => $fwnat,
		fwfilter    => $fwfilter,

		installurl	=> $installurl,
	}
}
