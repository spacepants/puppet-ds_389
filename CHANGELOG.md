# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org).

## Supported Release 1.1.1
### Summary
This release adds the ability to specify the minssf setting that controls StartTLS for non-SSL connections.

### Changed
* Parameterize nsslapd-minssf.
* Default nsslapd-minssf value changed to package default.
* ldif files are passed to ldapmodify directly instead of piping from stdout.

## Supported Release 1.1.0
### Summary
This release adds the ability to manage the content of both `ds_389::add` and `ds_389::modify` ldif files. This allows for better secret management and the use of template(), inline_template(), or inline_epp() when declaring these defined types.

### Changed
* Expose the content of an ldif file to allow for template-based management.
* Clean up references to the replication manager.
* The `bind_dn_pass` param for replication has been replaced with `replication_pass`.
* Added `replication_user` which defaults to 'Replication Manager'.
* `bind_dn` is now optional, and allows the bind DN for replication to be overriden if needed.

## Supported Release 1.0.0
### Summary
* Initial release.
