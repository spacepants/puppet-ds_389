# ds_389::modify
#
# Adds an ldif modify file to a 389 ds instance.
#
# @summary Adds an ldif modify file to a 389 ds instance.
#
# @example Adding an ldif modify file with required params.
#   ds_389::modify { 'modify_example_1':
#     server_id    => 'foo',
#     source       => 'puppet:///path/to/file.ldif',
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @example Adding an ldif modify file when using all params.
#   ds_389::modify { 'modify_example_2':
#     server_id       => 'foo',
#     source          => '/path/to/file.ldif',
#     root_dn         => 'cn=Directory Manager',
#     root_dn_pass    => 'supersecure',
#     server_host     => 'foo.example.com',
#     server_ssl_port => 1636,
#     user            => 'custom_user',
#     group           => 'custom_group',
#   }
#
# @param server_id The 389 ds instance name. Required.
# @param source The source path to use for the ldif file. Required.
# @param root_dn The bind DN to use when calling ldapmodify. Required.
# @param root_dn_pass The password to use when calling ldapmodify. Required.
# @param server_host The host to use when calling ldapmodify. Default: $::fqdn
# @param server_ssl_port The port to use when calling ldapmodify. Default: 636
# @param user The owner of the created ldif file. Default: $::ds_389::user
# @param group The group of the created ldif file. Default: $::ds_389::group
#
define ds_389::modify(
  String                            $server_id,
  String                            $source,
  String                            $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  String                            $server_host     = $::fqdn,
  Integer                           $server_ssl_port = 636,
  String                            $user            = $::ds_389::user,
  String                            $group           = $::ds_389::group,
) {
  include ::ds_389

  file { "/etc/dirsrv/slapd-${server_id}/${name}.ldif":
    ensure => file,
    mode   => '0440',
    owner  => $user,
    group  => $group,
    source => $source,
  }
  exec { "Modify ldif ${name}: ${server_id}":
    command => "cat /etc/dirsrv/slapd-${server_id}/${name}.ldif | ldapmodify -h ${server_host} -p ${server_ssl_port} -x -D \"${root_dn}\" -w ${root_dn_pass} ; touch /etc/dirsrv/slapd-${server_id}/${name}.done", # lint:ignore:140chars
    path    => '/usr/bin:/bin',
    creates => "/etc/dirsrv/slapd-${server_id}/${name}.done",
    require => File["/etc/dirsrv/slapd-${server_id}/${name}.ldif"],
  }
}
