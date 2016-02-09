/**
 * puppet script to define storage pools
 *
 * @note:
 *
 * this script does not create the required volume groups or partions
 * this must be done duringe the setup of the host.
 *
 * on hetzner for example define a partition to be delete after setup
 * vgcreate vg0 /dev/md3
 *
 *
 * creates a xml file for virsh to add a storage pool
 * and defines the pool
 *
 */
class kvmvirsh::pool(
    $ensure		= present,
    $poolname	= $::kvmvirsh::pool0,
    $type		= "logical",
	$sources	= [],
	$targets	= ["<path>/dev/${::kvmvirsh::pool0}</path>"],
	$autostart	= true,
	$physdevice = "/dev/md3",
) {


# ----------------------------------------------
# includes
# ----------------------------------------------

    include ::kvmvirsh

# ----------------------------------------------
# declarations
# ----------------------------------------------

	$xmlpath = "${::kvmvirsh::xmlpath}/pools"

# ----------------------------------------------
# main
# ----------------------------------------------


	if $type == 'logical' {
		exec{"create_pool_${poolname}_vg_${::kvmvirsh::pool0}":
		    command => "/sbin/vgcreate -c n ${::kvmvirsh::pool0} $physdevice",
			unless	=> "/sbin/vgscan | /bin/grep ${::kvmvirsh::pool0} | grep Found",
		}
	}

	if !defined(File["${xmlpath}"]) {
		file {"${xmlpath}":
			ensure 	=> directory,
			require => File["${::kvmvirsh::xmlpath}"],
		}
	}

	::kvmvirsh::pool::pool{"${poolname}":
    	ensure		=> $ensure,
    	type		=> $type,
		sources		=> $sources	,
		targets		=> $targets,
		autostart	=> $autostart,
		require		=> File["${xmlpath}"]
	}


}
