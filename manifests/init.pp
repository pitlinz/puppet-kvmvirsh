/**
 * class kvmvirsh
 *
 * install libvirt
 */
class kvmvirsh(
	$hostid 	= 00,
	$ipprefix	= '192.168.1',
	$extif		= 'eth0',
	$bridgename = 'virbr0',
	$localnet	= '192.168.0.0/16',

	$vnc_listen		= '0.0.0.0',
	$vnc_password	= undef,

	$pool0		= "vg0",
	$pool1		= undef,
	$domain		= undef,
) {

	include ::kvmvirsh::packages

    $xmlpath = "/etc/libvirt/kvmvirsh"

    file {"${xmlpath}":
    	ensure => directory,
    	require => Package["${::kvmvirsh::packages::pkg_libvirt}"],
    }

    $isopath = "/srv/kvm/cdrom"
    exec {"mkdir_${isopath}":
    	command => "/bin/mkdir -p ${isopath}",
		creates => $isopath,
	}


	# ---------------------------------------------
 	# install some helpfull tools
 	# ---------------------------------------------



	# --------------------------------------
	# some tool scripts to combine virsh commands
	# --------------------------------------

	# start / stop / restart virsh-network
	file {"/usr/local/bin/virsh-networking.sh":
	    mode => '0555',
	    owner => 'root',
		content => template('kvmvirsh/scripts/virsh-networking.sh.erb')
	}

	# start / stop / restart virsh-pool
	file {"/usr/local/bin/virsh-pool.sh":
	    mode => '0555',
	    owner => 'root',
		content => template('kvmvirsh/scripts/virsh-pool.sh.erb')
	}

	file {"${xmlpath}/tools":
	    ensure => directory,
	    require => File["${xmlpath}"]
	}

	file {"${xmlpath}/tools/install-puppet.sh":
	    content => template("kvmvirsh/scripts/installpuppet.sh.erb"),
	    mode	=> '0550',
		require => File["${xmlpath}/tools"]
	}


	# -----------------------------------------------
	# configure libvirt
	# -----------------------------------------------

	file{"/etc/libvirt/qemu.conf":
	    content => template("kvmvirsh/libvirt/qemu.conf.erb"),
	    require => Package["${::kvmvirsh::packages::pkg_libvirt}"],
	    notify  => Service["${::kvmvirsh::packages::service}"],
	}

    include ::kvmvirsh::network
    include ::kvmvirsh::pool

    if $pool1 == 'vg1' {
        include ::kvmvirsh::pool::vg1
    }

	# -----------------------------------------------
	# finaly the service
	# -----------------------------------------------

	service{"${::kvmvirsh::packages::service}":
	    ensure => running,
	}

}
