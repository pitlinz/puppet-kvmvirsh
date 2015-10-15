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

	case $ensure {
	    'present': {
	        exec{"pool_${disk[vgname]}_vol_${name}":
	       		command => "/usr/bin/virsh vol-create-as ${disk[vgname]} ${name} ${disk[size]} ${params}",
				unless	=> "/usr/local/bin/virsh-pool.sh volume ${disk[vgname]} status ${name}",
			}
	    }
	}
}
