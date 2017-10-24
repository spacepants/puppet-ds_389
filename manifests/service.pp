# ds_389::service
#
# Manages the service for and is generally intended to be called from a 389 ds instance.
#
# @summary Manages the service for and is generally intended to be called from a 389 ds instance.
#
# @param service_ensure The state the service should be in. Default: 'running'
# @param service_enable Whether the service should be enabled. Default: true
#
define ds_389::service(
  String  $service_ensure = 'running',
  Boolean $service_enable = true,
) {
  include ::ds_389
  $service_type = $::ds_389::params::service_type
  if $service_type == 'systemd' {
    service { "dirsrv@${name}":
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => true,
    }
  }
  else {
    file { "/etc/init.d/dirsrv@${name}":
      ensure  => file,
      mode    => '0755',
      content => template('ds_389/service-init.erb'),
    }
    service { "dirsrv@${name}":
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => true,
      require    => File["/etc/init.d/dirsrv@${name}"],
    }
  }
}
