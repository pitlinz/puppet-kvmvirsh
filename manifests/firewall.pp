/**
 * install firewall scripts in /etc/firewall
 *
 *
 */
 class kvmvirsh::firewall(
	$ensure 	= present,
	$hostid  	= $::kvmvirsh::hostid,
	$trustedips = undef,
	$routes	  	= [],
	$sshport	= "2200",
	$bridgeif 	= $::kvmvirsh::bridgename,
	$extif 		= $::kvmvirsh::extif,
	$tcpports 	= "80,443",
	$vlan_net	= $::kvmvirsh::localnet,

	$virbr		= "virbr0",
	$virnet		= "${::kvmvirsh::ipprefix}${::kvmvirsh::hostid}.0",
	$virnet1size= "24",
) {
	File{
		ensure  => $ensure,
	    owner   => 'root',
	    group   => 'root',
	    mode    => '0550',
	}

	if !defined(Package["ipcalc"]) {
		package{"ipcalc":
		    ensure => installed
		}
	}

  	if !defined(File["/etc/firewall"]) {
		file {"/etc/firewall":
	    	ensure => directory,
	    	mode    => '0750',
	  	}
	}

	file {"/etc/firewall/000-init.sh":
	    content => template("kvmvirsh/firewall/init.sh.erb"),
	    require	=> File["/etc/firewall"],
	}

	file {"/etc/firewall/010-routing.sh":
		content => template("kvmvirsh/firewall/routing.sh.erb"),
		require	=> File["/etc/firewall"],
	}

	if is_array($trustedips) {
	    $trustedlist = $trustedips
	} else {
	    if $trustedips == undef {
	        $trustedlist = []
	    } else {
	        $trustedlist = split($trustedips,"[,;]")
	    }
	}

	$trusttbl = "TRUSTED"
    file {"/etc/firewall/020-trusted.sh":
		content => template("kvmvirsh/firewall/trusted.sh.erb"),
		require	=> File["/etc/firewall"],
		notify  => Exec["/etc/firewall/020-trusted.sh"]
    }

    exec{"/etc/firewall/020-trusted.sh":
		command => "/etc/firewall/020-trusted.sh update",
		refreshonly => true
	}

	file {"/etc/init.d/firewall":
		content => template("kvmvirsh/firewall/firewall.erb"),
		require => File["/etc/firewall/000-init.sh","/etc/firewall/010-routing.sh"],
		notify  => Exec["update-rc-firewall"],
	}

	exec {"update-rc-firewall":
		command => "/usr/sbin/update-rc.d firewall defaults",
		refreshonly => true
    }


	file_line { "ssh_port_${sshport}":
  		line => 'Port 2200',
  		path => '/etc/ssh/sshd_config',
	}

	file {"/etc/libvirt/hooks/daemon":
	    content => template("kvmvirsh/libvirt/hooks/daemon.erb"),
	    require => Package["libvirt-bin"],
	}

	file {"/etc/libvirt/hooks/qemu":
	    content => template("kvmvirsh/libvirt/hooks/qemu.erb"),
	    require => Package["libvirt-bin"],
	}


	if !defined(Service["firewall"]) {
	    service{"firewall":
	        ensure 	=> running,
	        require	=> File["/etc/init.d/firewall"],
		}
	}
}
