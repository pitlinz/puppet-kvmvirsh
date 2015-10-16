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
			kvmvirsh::packages::package{[ 'ubuntu-virt-server', 'python-vm-builder', 'qemu', 'qemu-kvm', 'ruby-libvirt','bridge-utils','virtinst' ]:
			    ensure => latest
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
