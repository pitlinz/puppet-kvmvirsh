/**
 * define a disk pool for virsh
 *
 * @todo restart pool if params changes
 *
 */
define kvmvirsh::pool::pool(
    $ensure		= present,
    $type 		= "logical",
	$sources	= [],
	$targets	= ["<path>/dev/vg0</path>"],
	$autostart	= true,
) {

# --------------------------------------
# includes
# --------------------------------------

	include ::kvmvirsh

# --------------------------------------
# validation
# --------------------------------------

	validate_bool ($autostart)
	validate_re ($ensure, '^(present|defined|enabled|running|undefined|absent)$','Ensure must be one of defined (present), enabled (running), or undefined (absent).')

# --------------------------------------
# checks
# --------------------------------------

	if !defined(File["${::kvmvirsh::xmlpath}/pools"]) {
	    file {"${::kvmvirsh::xmlpath}/pools":
	        ensure 	=> directory,
	        require => File["${::kvmvirsh::xmlpath}"],
		}
	}


# --------------------------------------
# init
# --------------------------------------

	$xml_file 		= "${::kvmvirsh::pool::xmlpath}/${name}.xml"
	$ensure_file = $ensure? {
		/(present|defined|enabled|running)/ => 'present',
		/(undefined|absent)/                => 'absent',
		default								=> undef
	}


# --------------------------------------
# main
# --------------------------------------

	file {"${xml_file}":
	    ensure	=> $ensure_file,
	    content => template('kvmvirsh/libvirt/pool.xml.erb'),
		require => File["${::kvmvirsh::xmlpath}/pools"],
	}

	if $autostart {
	    $autoparam = "autostart"
	} else {
	    $autoparam = ""
	}

	case $ensure_file {
	    'present': {
			exec{"start_pool_${name}":
			    command => "/usr/local/bin/virsh-pool.sh start ${xml_file} ${autoparam}",
				require => File["${xml_file}","/usr/local/bin/virsh-pool.sh"],
				unless	=> "/usr/local/bin/virsh-pool.sh status ${name}",
			}
		}

		'absent': {
			exec{"stop_pool_${name}":
			    command => "/usr/local/bin/virsh-pool.sh stop ${xml_file}",
			    require => File["${xml_file}","/usr/local/bin/virsh-pool.sh"],
				unless	=> "/usr/local/bin/virsh-pool.sh status ${name} isstopped",
			}
		}
	}






}
