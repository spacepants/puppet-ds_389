require 'spec_helper'

describe 'ds_389' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'without any parameters' do
        it { is_expected.to compile }
        it { is_expected.to contain_class('ds_389::params') }
        it { is_expected.to contain_class('ds_389::install') }

        it { is_expected.to contain_file('/etc/dirsrv').with_ensure('directory') }

        it {
          is_expected.to contain_exec('Create ldap cacerts directory').with(
            command: '/bin/mkdir -p /etc/openldap/cacerts',
            creates: '/etc/openldap/cacerts',
          )
        }

        it {
          is_expected.to contain_package('389-ds-base').with(
            ensure: 'installed',
          ).that_requires(
            [
              'File[/etc/dirsrv]',
              'Exec[Create ldap cacerts directory]',
            ],
          )
        }

        it {
          is_expected.to contain_group('dirsrv').with(
            ensure: 'present',
            system: true,
          )
        }

        case os_facts[:osfamily]
        when 'Debian'
          it {
            is_expected.to contain_package('libnss3-tools').with(
              ensure: 'installed',
            )
          }

          it {
            is_expected.to contain_user('dirsrv').with(
              ensure: 'present',
              system: true,
              home: '/usr/share/dirsrv',
              shell: '/bin/false',
              gid: 'dirsrv',
            ).that_requires('Group[dirsrv]')
          }

          case os_facts[:operatingsystemmajrelease]
          when '8', '16.04'
            it {
              is_expected.to contain_ini_setting('dirsrv ulimit').with(
                ensure: 'present',
                path: '/etc/default/dirsrv.systemd',
                section: 'Service',
                setting: 'LimitNOFILE',
                value: '8192',
              ).that_requires('Package[389-ds-base]')
            }

          else
            it {
              is_expected.to contain_file_line('dirsrv ulimit').with(
                ensure: 'present',
                path: '/etc/default/dirsrv',
                line: 'ulimit -n 8192',
              ).that_requires('Package[389-ds-base]')
            }
          end

        when 'RedHat'
          it {
            is_expected.to contain_package('nss-tools').with(
              ensure: 'installed',
            )
          }

          it {
            is_expected.to contain_user('dirsrv').with(
              ensure: 'present',
              system: true,
              home: '/usr/share/dirsrv',
              shell: '/sbin/nologin',
              gid: 'dirsrv',
            ).that_requires('Group[dirsrv]')
          }

          case os_facts[:operatingsystemmajrelease]
          when '7'
            it {
              is_expected.to contain_ini_setting('dirsrv ulimit').with(
                ensure: 'present',
                path: '/etc/sysconfig/dirsrv.systemd',
                section: 'Service',
                setting: 'LimitNOFILE',
                value: '8192',
              ).that_requires('Package[389-ds-base]')
            }

          else
            it {
              is_expected.to contain_file_line('dirsrv ulimit').with(
                ensure: 'present',
                path: '/etc/sysconfig/dirsrv',
                line: 'ulimit -n 8192',
              ).that_requires('Package[389-ds-base]')
            }
          end
        end
      end

      context 'with parameter overrides' do
        let(:params) do
          {
            package_name: '389-ds-custom',
            user: 'custom_user',
            group: 'custom_group',
            cacerts_path: '/custom/cacerts/path',
            home_dir: '/custom/home/path',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('ds_389::params') }
        it { is_expected.to contain_class('ds_389::install') }

        it {
          is_expected.to contain_exec('Create ldap cacerts directory').with(
            command: '/bin/mkdir -p /custom/cacerts/path',
            creates: '/custom/cacerts/path',
          )
        }

        it {
          is_expected.to contain_package('389-ds-custom').with(
            ensure: 'installed',
          ).that_requires(
            [
              'File[/etc/dirsrv]',
              'Exec[Create ldap cacerts directory]',
            ],
          )
        }

        it {
          is_expected.to contain_group('custom_group').with(
            ensure: 'present',
            system: true,
          )
        }
        case os_facts[:osfamily]
        when 'Debian'
          it {
            is_expected.to contain_user('custom_user').with(
              ensure: 'present',
              system: true,
              home: '/custom/home/path',
              shell: '/bin/false',
              gid: 'custom_group',
            ).that_requires('Group[custom_group]')
          }
        when 'RedHat'
          it {
            is_expected.to contain_user('custom_user').with(
              ensure: 'present',
              system: true,
              home: '/custom/home/path',
              shell: '/sbin/nologin',
              gid: 'custom_group',
            ).that_requires('Group[custom_group]')
          }
        end
      end

      context 'when declaring an instance' do
        let(:params) do
          {
            instances: {
              'foo' => {
                'root_dn'      => 'cn=Directory Manager',
                'root_dn_pass' => 'supersecret',
                'suffix'       => 'dc=example,dc=com',
                'cert_db_pass' => 'secret',
                'server_id'    => 'foo',
              },
            },
          }
        end

        it { is_expected.to compile }

        it { is_expected.to contain_ds_389__instance('foo') }
        it { is_expected.to contain_ds_389__service('foo') }
        it { is_expected.to contain_ds_389__ssl('foo') }
        it { is_expected.to contain_exec('Add trust for CA: foo') }
        it { is_expected.to contain_exec('Add trust for server cert: foo') }
        it { is_expected.to contain_exec('Clean up temp files: foo') }
        it { is_expected.to contain_exec('Create cert DB: foo') }
        it { is_expected.to contain_exec('Export CA cert: foo') }
        it { is_expected.to contain_exec('Export server cert: foo') }
        it { is_expected.to contain_exec('Generate key pair: foo') }
        it { is_expected.to contain_exec('Generate noise file: foo') }
        it { is_expected.to contain_exec('Generate password file: foo') }
        it { is_expected.to contain_exec('Import ssl ldif: foo') }
        it { is_expected.to contain_exec('Make ca cert and add to database: foo') }
        it { is_expected.to contain_exec('Make server cert and add to database: foo') }
        it { is_expected.to contain_exec('Rehash cacertdir: foo') }
        it { is_expected.to contain_exec('Restart foo to enable SSL') }
        it { is_expected.to contain_exec('Set permissions on database directory: foo') }
        it { is_expected.to contain_exec('restart foo to pick up new token') }
        it { is_expected.to contain_exec('setup ds: foo') }
        it { is_expected.to contain_exec('stop foo to create new token') }
        it { is_expected.to contain_file('/etc/dirsrv/slapd-foo/pin.txt') }
        it { is_expected.to contain_file('/etc/dirsrv/slapd-foo/ssl.ldif') }
        it { is_expected.to contain_file('/etc/openldap/cacerts/fooCA.pem') }
        it { is_expected.to contain_file('/etc/openldap/cacerts/fooCert.pem') }
        case os_facts[:operatingsystemmajrelease]
        when '6', '14.04'
          it { is_expected.to contain_file('/etc/init.d/dirsrv@foo') }
        end
        it { is_expected.to contain_service('dirsrv@foo') }
        it { is_expected.to contain_anchor('foo_ldif_modify').that_requires('Service[dirsrv@foo]') }
        it { is_expected.to contain_anchor('foo_ldif_add') }
        it { is_expected.to contain_anchor('foo_ldif_base_load') }
      end
    end
  end
end
