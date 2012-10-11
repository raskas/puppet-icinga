class icinga::pnp4nagios ($mode     = undef,
                          $rra_step = 60,
                          $rra      = ['1:2880', '5:2880', '30:4320', '360:5840']) {

  include httpd

  package {
    'pnp4nagios':
      ensure => installed;
    'php-common':
      ensure => installed;
    'php':
      ensure => installed,
      notify => Service['httpd'];
    'php-gd':
      ensure => installed;
  }

  if $mode == 'bulk' {

    nagios_command {
      'process-service-perfdata-file':
        command_line => '/usr/local/pnp4nagios/libexec/process_perfdata.pl --bulk=/usr/local/pnp4nagios/var/service-perfdata';
      'process-host-perfdata-file':
        command_line => '/usr/local/pnp4nagios/libexec/process_perfdata.pl --bulk=/usr/local/pnp4nagios/var/host-perfdata';
    }

  }

  nagios_host {
    'pnp-host':
      action_url => '/pnp4nagios/graph?host=\$HOSTNAME$',
      register   => 0;
  }

  nagios_service {
    'pnp-service':
      action_url => '/pnp4nagios/graph?host=\$HOSTNAME$&srv=\$SERVICEDESC$',
      register   => 0;
  }

  nagios_command {
    'check_pnp_rrds':
      command_line => '\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_pnp_rrds';
  }

  file {
    '/etc/httpd/conf.d/pnp4nagios.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('icinga/pnp4nagios.conf.erb'),
      notify  => Service['httpd'];
    '/usr/local/pnp4nagios/etc/rra.cfg':
      owner   => 'icinga',
      group   => 'icinga',
      mode    => '0644',
      content => template('icinga/pnp4nagios_rra.cfg.erb');
    '/usr/local/pnp4nagios/etc/pages/':
      ensure  => directory,
      recurse => true,
      purge   => true;
  }

}

define pnp4nagios::page ( $page_name,
                          $page_category,
                          $graphs,
                          $use_regex = 0) {

  file {
    "/usr/local/pnp4nagios/etc/pages/${name}.cfg":
      owner   => 'icinga',
      group   => 'icinga',
      mode    => '0644',
      content => template('icinga/pnp4nagios_pages.cfg.erb'),
      require => Package['pnp4nagios'];
  }

}

