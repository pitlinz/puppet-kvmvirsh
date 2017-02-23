/**
 * install a foreman proxy to be able to define nodes via foreman
 *
 */
class kvmvirsh::foremanproxy(
	$http_port		= 8000,
	$https_port		= undef,
	$dhcp_vendor 	= 'virsh', 	# enable dhcp feature if a value is set
	$tftp_enabled	= 'true',	# enable tftp feature
) {
    include ::apt

/*
	if !defined(Package['software-properties-common']) {
		package{"software-properties-common":
		    ensure => latest,
		}
	}

	apt::ppa{"ppa:webupd8team/y-ppa-manager":}

	if !defined(Package["y-ppa-manager"]) {
	    package{"y-ppa-manger":
	        ensure => latests,
	        require => Apt::Ppa["ppa:webupd8team/y-ppa-manager"],
		}
	}
*/
	apt::source { "foreman":
    	location   => 'http://deb.theforeman.org',
    	repos      => 'stable',
    	key        => '7059542D5AEA367F78732D02B3484CB71AA043B8',
    	key_server => 'pgp.mit.edu',
    	notify	   => Exec["apt_update_foreman"],
    }

  	exec { "apt_update_foreman":
		command     => "${::apt::params::provider} update",
		logoutput   => 'on_failure',
		refreshonly => true,
		timeout     => $::apt::update_timeout,
		tries       => $::apt::update_tries,
		try_sleep   => 1
	}

    package{"foreman-proxy":
        ensure		=> latest,
        require		=> Apt::Source["foreman"]
	}

	file{"/etc/foreman-proxy/settings.yml":
	    content		=> template("kvmvirsh/foreman/proxy/settings.yml.erb"),
	    notify		=> Service["foreman-proxy"],
	    require		=> Package["foreman-proxy"]
	}

	file{"/etc/foreman-proxy/settings.d/dhcp.yml":
	    content		=> template("kvmvirsh/foreman/proxy/settings.d/dhcp.yml.erb"),
	    notify		=> Service["foreman-proxy"],
	    require		=> Package["foreman-proxy"]
	}

	if $tftp_enabled == 'true' or $tftp_enabled == 'http' or $tftp_enabled == 'https' {
	    # include ::tftp

	    if !defined(Package["kvm-ipxe"]) {
	        package{"kvm-ipxe":
	            ensure => latest
			}
	    }

	    $tftp_directory = $::tftp::directory
	} else {
	    $tftp_directory = undef
	}

	file{"/etc/foreman-proxy/settings.d/tftp.yml":
	    content		=> template("kvmvirsh/foreman/proxy/settings.d/tftp.yml.erb"),
	    notify		=> Service["foreman-proxy"],
	    require		=> Package["foreman-proxy"]
	}


	service{"foreman-proxy":
	    ensure		=> running,
	    require		=> Package["foreman-proxy"],
	}





}
