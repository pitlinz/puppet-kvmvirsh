/**
 * define needed libvirt params
 *
 */
class kvmvirsh::params(

) {
    include ::virt::params

	$package		= "$::virt::params::packages"
	$service 		= "$::virt::params::servicename"
}
