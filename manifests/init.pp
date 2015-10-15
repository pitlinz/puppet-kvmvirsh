/**
 * proxy module for virt
 *
 * to mange virtual nodes on kvm host with virsh and foreman
 *
 * uses some code from to configure virshk
 * @see https://github.com/thias/puppet-libvirt/blob/master/lib/puppet/provider/libvirt_pool/virsh.rb
 */
class kvmvirsh(
	$hostid 	= 00,
	$ipprefix	= '192.168.1',

) {
    include ::virt
    include ::kvmvirsh::params

    $xmlpath = "/etc/libvirt/kvmvirsh"

    file {"${xmlpath}":
    	ensure => directory,
    	require => Service[$::kvmvirsh::params::service],
    }

    $isopath = "/srv/kvm/cdrom"
    exec {"mkdir_${isopath}":
    	command => "/bin/mkdir -p ${isopath}",
		creates => $isopath,

	}


	# ---------------------------------------------
 	# install some helpfull tools
 	# ---------------------------------------------

	if !defined(Package["bridge-utils"]) {
	    package{"bridge-utils":
	        ensure => latest
		}
	}

	if !defined(Package["virtinst"]) {
	    package{"virtinst":
	        ensure => latest
		}
	}

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

    include ::kvmvirsh::network
    include ::kvmvirsh::pool



}
