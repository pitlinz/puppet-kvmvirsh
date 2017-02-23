/**
 * @see http://www.faqs.org/docs/Linux-mini/Remote-Bridging.html
 */
class kvmvirsh::network::tarpd(

) {
    file {"/usr/src/tarpd-1.6.tar.gz":
        source => "puppet:///modules/kvmvirsh/tarpd-1.6.tar.gz",
	}

	exec {"untar_tarpd-1.6.tar.gz":
	    command => "/usr/bin/tar -xzf /usr/src/tarpd-1.6.tar.gz",
		cwd => "/usr/src",
		creates => "/usr/src/tarpd-1.6"
	}

}
