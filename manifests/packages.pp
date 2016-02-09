/**
 * @module kvmvirsh
 * @class kvmvirsh::packages
 *
 * ---------------------------------------------------------
 * installs the required packages for a virsh + kvm host
 * ---------------------------------------------------------
 *
 */
class kvmvirsh::packages(

) {
    case $operatingsystem {
        'Ubuntu': {
            $service	 = "libvirt-bin"
            $pkg_libvirt = "libvirt-bin"
			kvmvirsh::packages::package{[ $pkg_libvirt, 'ubuntu-virt-server', 'python-vm-builder', 'qemu', 'qemu-kvm','bridge-utils','virtinst','virt-viewer']:
			    ensure => latest
			}

			case $operatingsystemrelease {
				'12.04': {
					kvmvirsh::packages::package{['kvm-ipxe', 'libvirt-ruby']:
					    ensure => latest,
					}
				}
				default: {
					kvmvirsh::packages::package{['ipxe-qemu', 'ruby-libvirt']:
					    ensure => latest,
					}
				}

			}
        }
    }
}

define kvmvirsh::packages::package(
    $ensure = latest,
) {
    if !defined(Package["${name}"]) {
        package{"${name}": ensure => $ensure}
    }
}
