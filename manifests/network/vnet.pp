# Define: kvmvirsh::network::vnet
#
# define, configure, enable and autostart a network for libvirt guests
#
# Parameters:
#  $ensure
#    Ensure this network is defined (present), or enabled (running), or undefined (absent)
#  $autostart
#    Whether to start this network at boot time
#  $bridge
#    Name of the bridge this network will be attached to
#  $forward_mode
#    One of nat, route, bridge, vepa, passthrough, private, hostdev
#  $forward_dev
#    The interface to forward, useful in bridge and route mode
#  $forward_interfaces
#    An array of interfaces to forwad
#  $ip and/or $ipv6 array hashes with
#    address
#    netmask (or alterntively prefix)
#    dhcp This is another hash that consists of
#      start - start of the range
#      end - end of the range
#      host - an array of hosts
#  Note: The following options are not supported on IPv6 networks
#    bootp_file - A file to serve for servers booting from PXE
#    bootp_server - Which server that file is served from
#  $mac - A MAC for this network, if none is defined, libvirt will chose one for you
#
# Sample Usage :
#
# $dhcp = {
#   start      => '192.168.122.2',
#   end        => '192.168.122.254',
#   bootp_file => 'pxelinux.0',
# }
# $pxe_ip = {
#   'address' => '192.168.122.2'
#   'prefix'  => '24'
#   'dhcp'    => $dhcp,
# }
# libvirt::network { 'pxe':
#   ensure       => 'enabled',
#   autostart    => true,
#   forward_mode => 'nat',
#   ip           => [ $pxe_ip ],
# }
#
# libvirt::network { 'direct-net'
#   ensure             => 'enabled',
#   autostart          => true,
#   forward_mode       => 'bridge',
#   forward_dev        => 'br0',
#   forward_interfaces => [ 'eth0', ],
# }
#
# $ipv6 = {
#   address => '2001:db8:ca2:2::1',
#   prefix  => '64',
# }
#
# libvirt::network { 'dual-stack'
#   ensure       => 'enabled',
#   autostart    => true,
#   forward_mode => 'nat',
#   ip           => [ $pxe_ip ],
#   ipv6         => [ $ipv6 ],
# }
#
define kvmvirsh::network::vnet (
  $ensure             = 'present',
  $autostart          = false,
  $bridge             = undef,
  $forward_mode       = 'route',
  $forward_dev        = undef,
  $forward_interfaces = ['eth0'],
  $ip                 = undef,
  $virtnet			  = undef,
  $ipv6               = undef,
  $mac                = undef,
) {

# --------------------------------------
# validation
# --------------------------------------

	validate_bool ($autostart)
	validate_re ($ensure, '^(present|defined|enabled|running|undefined|absent)$','Ensure must be one of defined (present), enabled (running), or undefined (absent).')

# --------------------------------------
# includes
# --------------------------------------

	include ::kvmvirsh

# --------------------------------------
# checks
# --------------------------------------

	if !defined(File["/etc/libvirt/kvmvirsh"]) {
	    file {"/etc/libvirt/kvmvirsh":
	        ensure 	=> directory,
	        require => Package["${::kvmvirsh::packages::pkg_libvirt}"],
		}
	}

	if !defined(File["/etc/libvirt/kvmvirsh/networks"]) {
	    file {"/etc/libvirt/kvmvirsh/networks":
	        ensure 	=> directory,
	        require => File["/etc/libvirt/kvmvirsh"],
		}
	}



# --------------------------------------
# definitions
# --------------------------------------

	$ensure_file = $ensure? {
		/(present|defined|enabled|running)/ => 'present',
		/(undefined|absent)/                => 'absent',
		default								=> undef
	}

	$xml_file 		= "${::kvmvirsh::network::xmlpath}/${name}.xml"
	$network_file   = "/etc/libvirt/qemu/networks/${name}.xml"
	$autostart_file = "/etc/libvirt/qemu/networks/autostart/${name}.xml"

	Exec{
	    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
	}

# --------------------------------------
# main
# --------------------------------------

	concat{"${xml_file}":
		ensure 	=> $ensure_file,
	}

	concat::fragment{"${xml_file}_head":
	    target	=> "${xml_file}",
		content	=> template("kvmvirsh/libvirt/networkfargments/head.erb"),
		order   => "00",
	}

	concat::fragment{"${xml_file}_forward":
	    target	=> "${xml_file}",
		content	=> template("kvmvirsh/libvirt/networkfargments/forward.erb"),
		order   => "10",
	}

	concat::fragment{"${xml_file}_bridge":
	    target	=> "${xml_file}",
		content	=> template("kvmvirsh/libvirt/networkfargments/bridge.erb"),
		order   => "20",
	}

	concat::fragment{"${xml_file}_ip_start":
	    target	=> "${xml_file}",
		content	=> template("kvmvirsh/libvirt/networkfargments/ip_start.erb"),
		order   => "30",
	}

	concat::fragment{"${xml_file}_ip_end":
	    target	=> "${xml_file}",
		content	=> template("kvmvirsh/libvirt/networkfargments/ip_end.erb"),
		order   => "39",
	}

	concat::fragment{"${xml_file}_close":
	    target	=> "${xml_file}",
	    content => "\n</network>\n",
	    order	=> "99"
	}

	case $ensure_file {
	    'present': {
	        if $autostart {
	            $vnetcapp = "autostart"
	        } else {
	            $vnetcapp = ""
	        }

	        #$vnetcommand = "/usr/local/bin/virsh-networking.sh restart ${xml_file} ${vnetcapp}"
	        $vnetcommand = "echo \"restart ${ip}\" > /tmp/virship "
			if !has_ip_address($ip['address']) {
				exec{"vnetcommand_${name}":
				    command 	=> $vnetcommand,
				}
			}

	    }
	    'absent': {
			#$vnetcommand = "/usr/local/bin/virsh-networking.sh stop ${xml_file} ${vnetcapp}"
			$vnetcommand = "echo \"stop ${ip}\" > /tmp/virship "
			if has_ip_address($ip['address']) {
				exec{"vnetcommand_${name}":
				    command 	=> $vnetcommand,
				}
			}
	    }
		default : {
			fail ("${module_name} This default case should never be reached in Libvirt::Network{'${name}':} on node ${::fqdn}.")
		}
	}


	if $virtnet != undef {
		file {"/etc/firewall/900-${name}.sh":
			mode 	=> '0550',
			content => template("kvmvirsh/firewall/virtnet.sh.erb"),
			require	=> File["/etc/firewall"],
		}
	}
}
