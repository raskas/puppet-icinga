class icinga::pnp4nagios {

  include httpd

  package {
    "pnp4nagios":
      ensure => installed;
    "php-common":
      ensure => installed;
    "php":
      ensure => installed;
    "php-gd":
      ensure => installed;
  }

  if $pnp4nagios_mode == "bulk" {

    nagios_command {
      "process-service-perfdata-file":
        command_line => "/usr/local/pnp4nagios/libexec/process_perfdata.pl --bulk=/usr/local/pnp4nagios/var/service-perfdata";
      "process-host-perfdata-file":
        command_line => "/usr/local/pnp4nagios/libexec/process_perfdata.pl --bulk=/usr/local/pnp4nagios/var/host-perfdata";
    }

  }

  nagios_host {
    "pnp-host":
      action_url => "/pnp4nagios/graph?host=\$HOSTNAME$",
      register   => 0;
  }

  nagios_service {
    "pnp-service":
      action_url => "/pnp4nagios/graph?host=\$HOSTNAME$&srv=\$SERVICEDESC$",
      register   => 0;
  }

  file {
    "/etc/httpd/conf.d/pnp4nagios.conf":
      owner   => "root",
      group   => "root",
      mode    => "0644",
      content => template("icinga/pnp4nagios.conf.erb"),
      notify  => Service["httpd"];
  }

}
