/**
 * handle a volumn
 *
 * $ensure: (present|absent)
 *
 * $size:
 * Use the suffixes k, M, G, T for kilobyte, megabyte, gigabyte, and terabyte, respectively.
 *
 *
 *
 */
define kvmvirsh::pool::vol(
    $ensure = present,
	$disk	= undef,
	$params	= '',
) {

# --------------------------------------
# validation
# --------------------------------------

	validate_re($ensure, '^(present|absent)$','Ensure must be one of present or absent.')
	validate_hash($disk)

# --------------------------------------
# main
# --------------------------------------

	$xml_file = "${::kvmvirsh::pool::xmlpath}/${disk[vgname]}_${name}.xml"

	case $ensure {
	    'present': {
	        exec{"pool_${disk[vgname]}_vol_${name}":
	       		command => "/usr/bin/virsh vol-create-as ${disk[vgname]} ${name} ${disk[size]} ${params}",
				unless	=> "/usr/local/bin/virsh-pool.sh volume ${disk[vgname]} status ${name}",
			}

	    }
	}

	$sourcedev 	= "/dev/${disk[vgname]}/${name}"
	$arr_target = split("${name}",'_')
	$targetdev  = $arr_target[(size($arr_target) - 1)]

	case $targetdev {
	    'hda': {
	        	$bus		= "ide"
				$address	= "<address type='drive' controller='0' bus='0' target='0' unit='0'/>"
			}
	    'hdb': {
	        	$bus		= "ide"
				$address	= "<address type='drive' controller='0' bus='0' target='0' unit='1'/>"
			}
	    'hdc': {
	        	$bus		= "ide"
				$address	= "<address type='drive' controller='0' bus='1' target='0' unit='0'/>"
			}
	    'hdd': {
	        	$bus		= "ide"
				$address	= "<address type='drive' controller='0' bus='1' target='0' unit='1'/>"
			}
		default: {
				$bus = "virtio"
			}
	}


	file {"${xml_file}":
	    ensure => $ensure,
	    content => template("kvmvirsh/libvirt/disk.xml.erb"),
	}


}
