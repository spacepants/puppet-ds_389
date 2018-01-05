require 'spec_helper'

describe 'ds_389::ssl' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specdirectory' }

  let(:ssl_default) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: sslVersionMin
sslVersionMin: TLS1.1
-
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off

dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
nsSSLPersonalitySSL: foo.example.com
nsSSLActivation: on
nsSSLToken: internal (software)
cn: RSA

dn: cn=config
changetype: modify
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-minssf
nsslapd-minssf: 0
-
replace: nsslapd-secureport
nsslapd-securePort: 636
'
  end

  let(:ssl_no_version_min) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off

dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
nsSSLPersonalitySSL: foo.example.com
nsSSLActivation: on
nsSSLToken: internal (software)
cn: RSA

dn: cn=config
changetype: modify
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-minssf
nsslapd-minssf: 0
-
replace: nsslapd-secureport
nsslapd-securePort: 636
'
  end

  let(:ssl_custom) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: sslVersionMin
sslVersionMin: TLS1.2
-
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off

dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
nsSSLPersonalitySSL: ldap.test.org
nsSSLActivation: on
nsSSLToken: internal (software)
cn: RSA

dn: cn=config
changetype: modify
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-minssf
nsslapd-minssf: 128
-
replace: nsslapd-secureport
nsslapd-securePort: 1636
'
  end

  let(:ssl_custom_no_version_min) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off

dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
nsSSLPersonalitySSL: ldap.test.org
nsSSLActivation: on
nsSSLToken: internal (software)
cn: RSA

dn: cn=config
changetype: modify
replace: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-minssf
nsslapd-minssf: 128
-
replace: nsslapd-secureport
nsslapd-securePort: 1636
'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          fqdn: 'foo.example.com',
        )
      end

      context 'with required params' do
        let(:params) do
          {
            cert_name: 'foo.example.com',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Import ssl ldif: specdirectory').with(
            command: 'ldapmodify -h foo.example.com -p 389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/ssl.ldif ; touch /etc/dirsrv/slapd-specdirectory/ssl.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/ssl.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/ssl.ldif]').that_notifies(
            'Exec[Restart specdirectory to enable SSL]',
          )
        }
        # rubocop:disable RepeatedExample
        case os_facts[:osfamily]
        when 'Debian'
          case os_facts[:operatingsystemmajrelease]
          when '8', '16.04'
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: ssl_default,
              )
            }

            it {
              is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
                command: 'systemctl restart dirsrv@specdirectory ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: ssl_no_version_min,
              )
            }

            it {
              is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
                command: 'service dirsrv restart specdirectory ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          end
        when 'RedHat'
          case os_facts[:operatingsystemmajrelease]
          when '7'
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: ssl_default,
              )
            }

            it {
              is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
                command: 'systemctl restart dirsrv@specdirectory ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'dirsrv',
                group: 'dirsrv',
                content: ssl_no_version_min,
              )
            }

            it {
              is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
                command: 'service dirsrv restart specdirectory ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          end
        end
        # rubocop:enable RepeatedExample
      end

      context 'with all params' do
        let(:title) { 'ldap01' }
        let(:params) do
          {
            cert_name: 'ldap.test.org',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
            server_host: 'ldap.test.org',
            server_port: 1389,
            server_ssl_port: 1636,
            user: 'custom_user',
            group: 'custom_group',
            minssf: 128,
            ssl_version_min: 'TLS1.2',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Import ssl ldif: ldap01').with(
            command: 'ldapmodify -h ldap.test.org -p 1389 -x -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-ldap01/ssl.ldif ; touch /etc/dirsrv/slapd-ldap01/ssl.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-ldap01/ssl.done',
          ).that_requires('File[/etc/dirsrv/slapd-ldap01/ssl.ldif]').that_notifies(
            'Exec[Restart ldap01 to enable SSL]',
          )
        }
        # rubocop:disable RepeatedExample
        case os_facts[:osfamily]
        when 'Debian'
          case os_facts[:operatingsystemmajrelease]
          when '8', '16.04'
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-ldap01/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'custom_user',
                group: 'custom_group',
                content: ssl_custom,
              )
            }

            it {
              is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
                command: 'systemctl restart dirsrv@ldap01 ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-ldap01/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'custom_user',
                group: 'custom_group',
                content: ssl_custom_no_version_min,
              )
            }

            it {
              is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
                command: 'service dirsrv restart ldap01 ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          end
        when 'RedHat'
          case os_facts[:operatingsystemmajrelease]
          when '7'
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-ldap01/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'custom_user',
                group: 'custom_group',
                content: ssl_custom,
              )
            }

            it {
              is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
                command: 'systemctl restart dirsrv@ldap01 ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/dirsrv/slapd-ldap01/ssl.ldif').with(
                ensure: 'file',
                mode: '0440',
                owner: 'custom_user',
                group: 'custom_group',
                content: ssl_custom_no_version_min,
              )
            }

            it {
              is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
                command: 'service dirsrv restart ldap01 ; sleep 2',
                path: '/usr/bin:/usr/sbin:/bin:/sbin',
                refreshonly: true,
              )
            }
          end
        end
        # rubocop:enable RepeatedExample
      end
    end
  end
end
