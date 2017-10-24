# ds_389::schema
#
# Adds a schema extension ldif file to a 389 ds instance.
#
# @summary Adds a schema extension ldif file to a 389 ds instance.
#
# @example Adding a schema extension with required params.
#   ds_389::schema { '50example':
#     server_id => 'foo',
#     source    => 'puppet:///path/to/file.ldif',
#   }
#
# @param server_id The 389 ds instance name. Required.
# @param source The source path to use for the ldif file. Required.
# @param user The owner of the created ldif file. Default: $::ds_389::user
# @param group The group of the created ldif file. Default: $::ds_389::group
#
define ds_389::schema(
  String $server_id,
  String $source,
  String $user      = $::ds_389::user,
  String $group     = $::ds_389::group,
) {
  include ::ds_389

  file { "/etc/dirsrv/slapd-${server_id}/schema/${name}.ldif":
    ensure => file,
    owner  => $user,
    group  => $group,
    mode   => '0440',
    source => $source,
    notify => Service["dirsrv@${server_id}"],
  }
}
