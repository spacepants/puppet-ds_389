require 'spec_helper'

describe 'ds_389::service' do
  let(:pre_condition) { 'include ::ds_389' }
  let(:title) { 'specdirectory' }
  let(:service_default) do
    '#!/bin/sh
#
# dirsrv    This starts and stops the specdirectory dirsrv instance
#
# chkconfig:   - 79 21
# description: 389 Directory Server instance wrapper
# processname: /usr/sbin/ns-slapd
# configdir:   /etc/dirsrv/
# piddir:      /var/run/dirsrv
# datadir:     /var/lib/dirsrv/slapd-specdirectory
#

case "$1" in
    start)
    /etc/init.d/dirsrv start specdirectory
    ;;
    stop)
    /etc/init.d/dirsrv stop specdirectory
    ;;
    restart)
    /etc/init.d/dirsrv restart specdirectory
    ;;
    status)
    /etc/init.d/dirsrv status specdirectory
    ;;
    *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0
'
  end

  let(:service_custom) do
    '#!/bin/sh
#
# dirsrv    This starts and stops the ldap01 dirsrv instance
#
# chkconfig:   - 79 21
# description: 389 Directory Server instance wrapper
# processname: /usr/sbin/ns-slapd
# configdir:   /etc/dirsrv/
# piddir:      /var/run/dirsrv
# datadir:     /var/lib/dirsrv/slapd-ldap01
#

case "$1" in
    start)
    /etc/init.d/dirsrv start ldap01
    ;;
    stop)
    /etc/init.d/dirsrv stop ldap01
    ;;
    restart)
    /etc/init.d/dirsrv restart ldap01
    ;;
    status)
    /etc/init.d/dirsrv status ldap01
    ;;
    *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0
'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'without any params' do
        it { is_expected.to compile }

        # rubocop:disable RepeatedExample
        case os_facts[:osfamily]
        when 'Debian'
          case os_facts[:operatingsystemmajrelease]
          when '8', '16.04'
            it {
              is_expected.to contain_service('dirsrv@specdirectory').with(
                ensure: 'running',
                enable: true,
                hasrestart: true,
                hasstatus: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/init.d/dirsrv@specdirectory').with(
                ensure: 'file',
                mode: '0755',
                content: service_default,
              )
            }

            it {
              is_expected.to contain_service('dirsrv@specdirectory').with(
                ensure: 'running',
                enable: true,
                hasrestart: true,
                hasstatus: true,
              ).that_requires('File[/etc/init.d/dirsrv@specdirectory]')
            }
          end
        when 'RedHat'
          case os_facts[:operatingsystemmajrelease]
          when '7'
            it {
              is_expected.to contain_service('dirsrv@specdirectory').with(
                ensure: 'running',
                enable: true,
                hasrestart: true,
                hasstatus: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/init.d/dirsrv@specdirectory').with(
                ensure: 'file',
                mode: '0755',
                content: service_default,
              )
            }

            it {
              is_expected.to contain_service('dirsrv@specdirectory').with(
                ensure: 'running',
                enable: true,
                hasrestart: true,
                hasstatus: true,
              ).that_requires('File[/etc/init.d/dirsrv@specdirectory]')
            }
          end
        end
        # rubocop:enable RepeatedExample
      end

      context 'with all params' do
        let(:title) { 'ldap01' }
        let(:params) do
          {
            service_ensure: 'stopped',
            service_enable: false,
          }
        end

        it { is_expected.to compile }

        # rubocop:disable RepeatedExample
        case os_facts[:osfamily]
        when 'Debian'
          case os_facts[:operatingsystemmajrelease]
          when '8', '16.04'
            it {
              is_expected.to contain_service('dirsrv@ldap01').with(
                ensure: 'stopped',
                enable: false,
                hasrestart: true,
                hasstatus: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/init.d/dirsrv@ldap01').with(
                ensure: 'file',
                mode: '0755',
                content: service_custom,
              )
            }

            it {
              is_expected.to contain_service('dirsrv@ldap01').with(
                ensure: 'stopped',
                enable: false,
                hasrestart: true,
                hasstatus: true,
              ).that_requires('File[/etc/init.d/dirsrv@ldap01]')
            }
          end
        when 'RedHat'
          case os_facts[:operatingsystemmajrelease]
          when '7'
            it {
              is_expected.to contain_service('dirsrv@ldap01').with(
                ensure: 'stopped',
                enable: false,
                hasrestart: true,
                hasstatus: true,
              )
            }
          else
            it {
              is_expected.to contain_file('/etc/init.d/dirsrv@ldap01').with(
                ensure: 'file',
                mode: '0755',
                content: service_custom,
              )
            }

            it {
              is_expected.to contain_service('dirsrv@ldap01').with(
                ensure: 'stopped',
                enable: false,
                hasrestart: true,
                hasstatus: true,
              ).that_requires('File[/etc/init.d/dirsrv@ldap01]')
            }
          end
        end
        # rubocop:enable RepeatedExample
      end
    end
  end
end
