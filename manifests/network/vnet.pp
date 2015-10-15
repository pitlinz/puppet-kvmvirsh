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
  $forward_interfaces = [],
  $ip                 = undef,
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

	include ::kvmvirsh::params

# --------------------------------------
# checks
# --------------------------------------

	if !defined(File["/etc/libvirt/kvmvirsh"]) {
	    file {"/etc/libvirt/kvmvirsh":
	        ensure 	=> directory,
	        require => Package[$::kvmvirsh::params::package],
		}
	}

	if !defined(File["/etc/libvirt/kvmvirsh/pool"]) {
	    file {"/etc/libvirt/kvmvirsh/pool":
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


	file {"${xml_file}":
	    ensure 	=> $ensure_file,
	    content => template('kvmvirsh/libvirt/network.xml.erb'),
	}

	case $ensure_file {
		'present': {
			exec { "virsh-net-define-${name}":
				command => "virsh net-define ${xml_file}",
				unless  => "virsh -q net-list --all | grep -Eq '^\s*${name}'",
				require => File["${xml_file}"],
			}
			if $autostart {
				exec { "virsh-net-autostart-${name}":
					command => "virsh net-autostart ${name}",
					require => Exec["virsh-net-define-${name}"],
					creates => $autostart_file,
				}
			}

			if $ensure in [ 'enabled', 'running' ] {
				exec { "virsh-net-start-${name}":
					command => "virsh net-start ${name}",
					require => Exec["virsh-net-define-${name}"],
					unless  => "virsh -q net-list --all | grep -Eq '^\s*${name}\\s+active'",
				}
  			}

		}

		'absent': {
			exec { "virsh-net-destroy-${name}":
				command => "virsh net-destroy ${name}",
				onlyif  => "virsh -q net-list --all | grep -Eq '^\s*${name}\\s+active'",
			}
			exec { "virsh-net-undefine-${name}":
				command => "virsh net-undefine ${name}",
				onlyif  => "virsh -q net-list --all | grep -Eq '^\s*${name}\\s+inactive'",
				require => Exec["virsh-net-destroy-${name}"],
			}

			file { [ $network_file, $autostart_file ]:
				ensure  => absent,
				require => Exec["virsh-net-undefine-${name}"],
		  	}
		}
		default : {
			fail ("${module_name} This default case should never be reached in Libvirt::Network{'${name}':} on node ${::fqdn}.")
		}

	}

}
