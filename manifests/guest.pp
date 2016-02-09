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
	$netname	  = "${::kvmvirsh::netname}",
	$guestintip   = undef,
	$guestmacaddr = undef,
	$hostbrname   = undef,

	$guestextip   = $::ipaddress,
	$guestextname = undef,
	$hostexitif   = "eth0",

	$tcpports	  = undef,
	$fwnat        = [],
	$fwfilter     = [],
	$guestdomain  = "${::kvmvirsh::domain}",

	# disks params
	$guestdrbd    = false,
	$guestdisks   = undef,
	# alternativ disk param method
  	$hda = undef,
	$hdb = undef,
	$hdc = undef,
	$hdd = undef,

	$osvariant		= "ubuntutrusty",
	$isoimage 		= undef,
	$isoimagesrc	= "http://releases.ubuntu.com/14.04/ubuntu-14.04.3-server-amd64.iso",
	$installurl		= "http://ftp.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64/"
) {

	include ::kvmvirsh::network

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
	$network = " --network network=${netname},model=virtio,mac=${macaddr}"


	if is_ip_address($guestintip) {
	    $intip = $guestintip
	} else {
	    $intip = "${::kvmvirsh::network::ipaddrpre}.${vncid}"
	}

	if $netname == "default" {
		exec { "add_mac${macaddr}_to_net${netname}":
		    command => "/usr/bin/virsh net-update ${netname} add ip-dhcp-host \"<host mac='${macaddr}' name='${name}.${guestdomain}' ip='${intip}' />\" --live --config",
			unless => "/bin/grep  '${macaddr}' /etc/libvirt/qemu/networks/${netname}.xml"
		}

		if !defined(Host["${name}.${guestdomain}"]) {
			host{"${name}.${guestdomain}":
			    ip => $intip
			}
		}
	}

    $xml_file 		= "${::kvmvirsh::network::xmlpath}/${netname}.xml"
    concat::fragment{"${xml_file}_ip_${netname}_${name}":
		target	=> "${xml_file}",
		content => "\t\t<host mac='${macaddr}' name='${name}' ip='${intip}' />\n",
		order   => "35",
	}

	# firewall
	if $vncid < 10 {
		$sshport = "220${vncid}"
	} else {
	    $sshport = "22${vncid}"
	}

	::kvmvirsh::guest::firewall{"$name":
	    intip		=> "${intip}",
		extip		=> "${guestextip}",
	    sshport 	=> $sshport,
		tcpports 	=> $tcpports,
		fwnat       => $fwnat,
		fwfilter    => $fwfilter,
	}


	# -------------------------------------
	# disks
	# -------------------------------------

	if is_hash($hda) {
	    ::kvmvirsh::pool::vol{"${name}_hda": disk => $hda, params => $diskparams }
	    $vidisk_a = " --disk vol=${hda[vgname]}/${name}_hda"
	    $require_hda = ["${name}_hda"]
	} else {
	    $require_hda = []
	    $vidisk_a = ""
	}

	if is_hash($hdb) {
	    ::kvmvirsh::pool::vol{"${name}_hdb": disk => $hdb, params => $diskparams }
	    $vidisk_b = " --disk vol=${hdb[vgname]}/${name}_hdb"
	    $require_hdb = ["${name}_hdb"]
	} else {
	    $vidisk_b = ""
	    $require_hdb = []
	}

	if is_hash($hdc) {
	    ::kvmvirsh::pool::vol{"${name}_hdc": disk => $hdc, params => $diskparams }
	    $vidisk_c = " --disk vol=${hdc[vgname]}/${name}_hdc"
	    $require_hdc = ["${name}_hdc"]
	} else {
	    $vidisk_c = ""
	    $require_hdc = []
	}

	if is_hash($hdd) {
	    ::kvmvirsh::pool::vol{"${name}_hdd": disk => $hdd, params => $diskparams }
	    $vidisk_d = " --disk vol=${hdd[vgname]}/${name}_hdd"
	    $require_hdd = ["${name}_hdd"]
	} else {
	    $vidisk_d = ""
	    $require_hdd = []
	}

	$diskparams = "${vidisk_a} ${vidisk_b} ${vidisk_c} ${vidisk_d}"
	$hd_require = [$require_hda,$require_hdb,$require_hdc,$require_hdd]

	# install media --------------------------------

	if $isoimage != undef and $isoimagesrc != undef {
		exec{"wget_${isoimage}_${name}":
		    command => "/usr/bin/wget -O ${isoimage} ${isoimagesrc}",
		    cwd 	=> "${::kvmvirsh::isopath}",
			creates => "${::kvmvirsh::isopath}/${isoimage}",
			require => Exec["mkdir_${::kvmvirsh::isopath}"],
		}
		$viinst = "-c ${::kvmvirsh::isopath}/${isoimage}"
	} elsif $installurl != undef {
	    $viinst = "-l ${installurl}"
	}

	# grafiks
	if $vncid < 10 {
		$vivnc = " --graphics vnc,port=590${vncid},keymap=de"
	} else {
	    $vivnc = " --graphics vnc,port=59${vncid},keymap=de"
	}

	# exec virt-install
	$toolpath = "${::kvmvirsh::xmlpath}/tools"
	file{"${toolpath}/install_${name}":
	    mode	=> '700',
	    content	=> "/usr/bin/virt-install --os-variant $osvariant $vibasik $network $diskparams $vivnc $viinst\n"
	}

	exec{"virtinstall_${name}":
	    command => "/usr/bin/virt-install --os-variant $osvariant $vibasik $network $diskparams $vivnc $viinst",
		creates => "/etc/libvirt/qemu/${name}.xml",
		require => Kvmvirsh::Pool::Vol[$hd_require]
	}

	if $autostart {
		exec{"autostart_${name}":
		    command => "/usr/bin/virsh autostart ${name}",
			creates => "/etc/libvirt/qemu/autostart/${name}.xml",
			require	=> Exec["virtinstall_${name}"],
		}
	}

	if $guestextname != undef {
		include ::kvmvirsh::guest::cloudflaire
		::kvmvirsh::guest::cloudfaire::dnsentry{"${guestextname}":
			ip => "${guestextip}",
		}
	}


}
