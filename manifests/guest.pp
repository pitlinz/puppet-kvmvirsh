/**
 * define a vnode
 *
 * --------------------------------------
 * @param hd?:
 * hash with attributes: type,size,vgname
 * example:
 * <code>
   	$hda        = {
		type    => 'lvm',
		size    => '60G',
		vgname  => 'vg0'
	}
 * </code>
 *
 */
define kvmvirsh::guest(
	$ensure       = present,
	$autostart    = false,
    $vncid        = 0,

	#cpu/memory
	$guestcpus    = "1",
	$guestmemory  = "1024",

	#network params
	$guestintip   = false,
	$guestmacaddr = undef,
	$hostbrname   = undef,

	$guestextip   = undef,
	$hostexitif   = "eth0",
	$fwnat        = [],
	$fwfilter     = [],

	# disks params
	$guestdrbd    = false,
	$guestdisks   = undef,
	# alternativ disk param method
  	$hda = undef,
	$hdb = undef,
	$hdc = undef,
	$hdd = undef,


	$isoimage 		= undef,
	$isoimagesrc	= "http://releases.ubuntu.com/14.04/ubuntu-14.04.3-server-amd64.iso",
	$installurl		= "http://ftp.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64/"
) {

	# -------------------------------------
	# basic settings
	# -------------------------------------

	$vibasik = " -n ${name} -r ${guestmemory} --vcpus=${guestcpus} "

	# -------------------------------------
	# network
	# -------------------------------------

	if $guestmacaddr == undef {
	    if $vncid < 10 {
	        $macaddr = "${::kvmvirsh::network::macaddrpre}0${vncid}"
	    } else {
	        $macaddr = "${::kvmvirsh::network::macaddrpre}$vncid"
	    }
	} else {
	    $macaddr = $guestmacaddr
	}
	$network = " --network network=default,model=virtio,mac=${macaddr}"

	# -------------------------------------
	# disks
	# -------------------------------------

	if is_hash($hda) {
	    ::kvmvirsh::pool::vol{"${name}_hda": disk => $hda, params => $diskparams }
	    $vidisk_a = " --disk vol=${hda[vgname]}/${name}_hda"
	} else {
	    $vidisk_a = ""
	}

	if is_hash($hdb) {
	    ::kvmvirsh::pool::vol{"${name}_hdb": disk => $hdb, params => $diskparams }
	    $vidisk_b = " --disk vol=${hdb[vgname]}/${name}_hdb"
	} else {
	    $vidisk_b = ""
	}

	if is_hash($hdc) {
	    ::kvmvirsh::pool::vol{"${name}_hdc": disk => $hdc, params => $diskparams }
	    $vidisk_c = " --disk vol=${hdc[vgname]}/${name}_hdc"
	} else {
	    $vidisk_c = ""
	}

	if is_hash($hdd) {
	    ::kvmvirsh::pool::vol{"${name}_hdd": disk => $hdd, params => $diskparams }
	    $vidisk_d = " --disk vol=${hdd[vgname]}/${name}_hdd"
	} else {
	    $vidisk_d = ""
	}

	$diskparams = "${vidisk_a} ${vidisk_b} ${vidisk_c} ${vidisk_d}"


	# install media --------------------------------

	if $isoimage != undef and $isoimagesrc != undef {
		exec{"wget_${isoimage}_${name}":
		    command => "/usr/bin/wget -O ${isoimage} ${isoimagesrc}",
		    cwd 	=> "${::kvmvirsh::isopath}",
			creates => "${::kvmvirsh::isopath}/${isoimage}",
			require => Exec["mkdir_${::kvmvirsh::isopath}"],
		}
	} elsif $installurl != undef {
	    $viinst = "-l ${installurl}"
	}

	# grafiks
	if $vncid < 10 {
		$vivnc = " --graphics vnc,port=590${vncid}"
	} else {
	    $vivnc = " --graphics vnc,port=59${vncid}"
	}


	# exec virt-install

	exec{"virtinstall_${name}":
	    command => "/usr/bin/virt-install $vibasik $network $diskparams $viinst",
		creates => "/etc/libvirt/qemu/${name}.xml",
	}



}
