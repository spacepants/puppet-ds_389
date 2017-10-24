require 'spec_helper'

describe 'ds_389::modify' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specmodify' }

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
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specmodify.ldif',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/specmodify.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'dirsrv',
            group: 'dirsrv',
            source: 'puppet:///specfiles/specmodify.ldif',
          )
        }
        it {
          is_expected.to contain_exec('Modify ldif specmodify: specdirectory').with(
            command: 'cat /etc/dirsrv/slapd-specdirectory/specmodify.ldif | ldapmodify -h foo.example.com -p 636 -x -D "cn=Directory Manager" -w supersecure ; touch /etc/dirsrv/slapd-specdirectory/specmodify.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/specmodify.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/specmodify.ldif]')
        }
      end

      context 'with all params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            source: 'puppet:///specfiles/specmodify.ldif',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
            server_host: 'ldap.test.org',
            server_ssl_port: 1636,
            user: 'specuser',
            group: 'specgroup',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/specmodify.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'specuser',
            group: 'specgroup',
            source: 'puppet:///specfiles/specmodify.ldif',
          )
        }
        it {
          is_expected.to contain_exec('Modify ldif specmodify: specdirectory').with(
            command: 'cat /etc/dirsrv/slapd-specdirectory/specmodify.ldif | ldapmodify -h ldap.test.org -p 1636 -x -D "cn=Directory Manager" -w supersecure ; touch /etc/dirsrv/slapd-specdirectory/specmodify.done', # rubocop:disable LineLength
            path: '/usr/bin:/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/specmodify.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/specmodify.ldif]')
        }
      end
    end
  end
end
