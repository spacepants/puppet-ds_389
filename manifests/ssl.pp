# ds_389::ssl
#
# Manages ssl for and is intended to be called by a 389 ds instance.
#
# @summary Manages ssl for and is intended to be called by a 389 ds instance.
#
# @example
#   ds_389::ssl { 'foo':
#     cert_name    => 'fooCert'
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @param cert_name The nickname of the SSL cert to use. Required.
# @param root_dn The bind DN to use when calling ldapmodify. Required.
# @param root_dn_pass The password to use when calling ldapmodify. Required.
# @param server_host The host to use when calling ldapmodify. Default: $::fqdn
# @param server_port The port to use when calling ldapmodify. Default: 389
# @param server_ssl_port The port to use when calling ldapmodify. Default: 636
# @param user The owner of the created ldif file. Default: $::ds_389::user
# @param group The group of the created ldif file. Default: $::ds_389::group
# @param ssl_version_min The minimum TLS version to allow. Default: 'TLS1.1'
#
define ds_389::ssl(
  String                            $cert_name,
  String                            $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  String                            $server_host     = $::fqdn,
  Integer                           $server_port     = 389,
  Integer                           $server_ssl_port = 636,
  String                            $user            = $::ds_389::user,
  String                            $group           = $::ds_389::group,
  String                            $ssl_version_min = 'TLS1.1',
) {
  include ::ds_389

  $ssl_version_min_support = $::ds_389::params::ssl_version_min_support
  if $::ds_389::params::service_type == 'systemd' {
    $service_restart_command = "systemctl restart dirsrv@${name}"
  }
  else {
    $service_restart_command = "service dirsrv restart ${name}"
  }

  file { "/etc/dirsrv/slapd-${name}/ssl.ldif":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template('ds_389/ssl.erb'),
  }
  exec { "Import ssl ldif: ${name}":
    command => "ldapmodify -h ${server_host} -p ${server_port} -x -D \"${root_dn}\" -w ${root_dn_pass} -f /etc/dirsrv/slapd-${name}/ssl.ldif ; touch /etc/dirsrv/slapd-${name}/ssl.done", # lint:ignore:140chars
    path    => '/usr/bin:/bin',
    creates => "/etc/dirsrv/slapd-${name}/ssl.done",
    require => File["/etc/dirsrv/slapd-${name}/ssl.ldif"],
    notify  => Exec["Restart ${name} to enable SSL"],
  }
  exec { "Restart ${name} to enable SSL":
    command     => "${service_restart_command} ; sleep 2",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true,
  }
}
