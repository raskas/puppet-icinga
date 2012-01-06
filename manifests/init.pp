
class icinga ( $pnp4nagios_mode = undef,
               $pnp4nagios_rra_step = undef,
               $pnp4nagios_rra = undef ) {

  if $pnp4nagios_mode {
    class {
      "icinga::pnp4nagios":
        mode     => $pnp4nagios_mode,
        rra_step => $pnp4nagios_rra_step,
        rra      => $pnp4nagios_rra;
    }
  }

  # Setting the authenticaton variable to an empty string
  # it will disable all authentication, any other value will enable it
  $authentication=""

  # cgi.cfg
  $default_user_name="icingaadmin"

  include httpd

  package {
    "icinga":
      ensure => installed;
    "icinga-doc":
      ensure => installed;
    "icinga-gui":
      ensure => installed;
    "nagios-plugins-ping":
      ensure => installed;
    "nagios-plugins-ssh":
      ensure => installed;
  }

  service {
    "icinga":
      ensure    => running,
      enable    => true,
      hasstatus => true,
      require   => Package["icinga"];
  }

  file {
    "/etc/httpd/conf.d/icinga.conf":
      owner   => "root",
      group   => "root",
      mode    => "0644",
      content => template("icinga/httpd.conf.erb"),
      notify  => Service["httpd"];
    "/etc/icinga/cgi.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      content => template("icinga/cgi.cfg.erb"),
      require => Package["icinga"];
    "/etc/icinga/icinga.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      content => template("icinga/icinga.cfg.erb"),
      notify  => Service["icinga"],
      require => Package["icinga"];
    "/etc/icinga/resource.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      source  => "puppet:///modules/icinga/resource.cfg",
      notify  => Service["icinga"],
      require => Package["icinga"];
    "/etc/nagios":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      recurse => true,
      purge   => true,
      force   => true,
      ensure  => directory;
    "/etc/nagios/nagios_templates.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      source  => "puppet:///modules/icinga/templates.cfg",
      notify  => Service["icinga"];
    "/etc/nagios/nagios_host.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      ensure  => file;
    "/etc/nagios/nagios_hostgroup.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      ensure  => file;
    "/etc/nagios/nagios_service.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      ensure  => file;
    "/etc/nagios/nagios_command.cfg":
      owner   => "icinga",
      group   => "icinga",
      mode    => "0664",
      ensure  => file;
  }

  resources {
    ["nagios_host","nagios_hostgroup","nagios_service"]:
      purge => true;
  }

#  nagios_hostgroup {
#    "linux":
#      ensure => present;
#  }

}

class icinga::storeconfig {

  include icinga

  Nagios_host <<| tag == 'icinga' |>>
  Nagios_host  <| tag == 'icinga' |> {
    notify  => Service["icinga"],
  }

  Nagios_service <<| tag == 'icinga' |>>
  Nagios_service  <| tag == 'icinga' |> {
    notify  => Service["icinga"],
  }

}

class icinga::nagios-plugins-snmp {

  package {
    "nagios-plugins-snmp-extras":
      ensure => installed;
  }

  nagios_command {
    "check_snmp_int":
      command_line => "\$USER1$/check_snmp_int -H \$HOSTADDRESS$ -C public -n \$ARG1$ -w 0,0 -c 0,0 -r -k -Y -f -B -d 60 \$ARG2$";
    "check_snmp_load":
      command_line => "\$USER1$/check_snmp_load -H \$HOSTADDRESS$ -C public -T cisco -w 80,80,80 -c 90,90,90 -f";
    "check_snmp_mem":
      command_line => "/usr/bin/perl \$USER1$/check_snmp_mem -H \$HOSTADDRESS$ -C public -I -w 80 -c 90 -f";
  }

}

class icinga::nagios-plugins-ntc {

  include icinga::nagios-plugins-nrpe

  package {
    "nagios-plugins-ntc":
      ensure => installed;
  }

  # semscmd
  nagios_command {
    "check_AMP_loggedonsits":
      command_line => "/usr/bin/perl \$USER1$/check_semscmd --host \$HOSTADDRESS$ --statistic ntcSeEqAmpLonSits --description \"Logged on sits\" --instances 2";
    "check_active_chain":
      command_line => "/usr/bin/perl \$USER1$/check_semscmd --host CA_SS_ --statistic 1.ntcSeSsChainSelection --description \"Current active chain (1=A, 2=B)\"";
    "check_BDM_clippingratio":
      command_line => "/usr/bin/perl \$USER1$/check_semscmd --host \$HOSTADDRESS$ --statistic ntcSeEqBuDemALCRatioDb2 --description \"Clipping ratio\" --unit dB";
    "check_BDM_tunergainoffset":
      command_line => "/usr/bin/perl \$USER1$/check_semscmd --host \$HOSTADDRESS$ --statistic ntcSeEqBuDemTunerOffset --description \"Tuner gain offset\"";
    "check_FWMOD_PLefficiency":
      command_line => "/usr/bin/perl \$USER1$/check_semscmd --host \$HOSTADDRESS$ --statistic ntcSeEqMoPLEfficiency --description \"PL efficiency\" --unit \"%\"";
  }

  nagios_command {
    "check_cpu_usage":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_cpu_usage";
    "check_mem_usage":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_mem_usage";
    "check_whoami":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_whoami";
    "check_java_memory":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_java_memory -a \$ARG1$";
    "check_process_status":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_process_status -a \$ARG1$";
  }

}

class icinga::nagios-plugins-tellitec {

  package {
    "nagios-plugins-tellitec":
      ensure => installed;
  }

  nagios_command {  # TC-SHAPE
    "check_tc-shape-server_shaping-rates":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CAPT_RATE --statistic FORW_RATE --statistic GUAR_RATE --statistic DROP_RATE \$ARG2$";
    "check_tc-shape-server_encapsulation-bitrates":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic IP_BIT_RATE --statistic PAY_BIT_RATE --statistic PAD_BIT_RATE \$ARG2$";
    "check_tc-shape-server_encapsulation-framerates":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic FRAME_RATE --statistic FRAME_DROP_RATE \$ARG2$";
    "check_tc-shape-server_encapsulation-symbolrates":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic SYMB_RATE --statistic SYMB_DROP_RATE --statistic TARG_SYMB_RATE \$ARG2$";
    "check_tc-shape-server_encapsulation-packetrates":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic IP_PACK_RATE \$ARG2$";
    "check_tc-shape-server_encapsulation-queue":
      command_line => "/usr/bin/perl \$USER1$/check_tc-shape-server --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CURR_QUEUE_SIZE \$ARG2$";
  }

  nagios_command {  # TC-NET
    "check_tc-net-server_connectedclients":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CONN_CL \$ARG2$";
    "check_tc-net-server_httpclientconnections":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic HTTP_CL_CONN \$ARG2$";
    "check_tc-net-server_httpserverconnections":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic HTTP_SERV_CONN \$ARG2$";
    "check_tc-net-server_httpthroughput":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic HTTP_THR \$ARG2$";
    "check_tc-net-server_capturingclientconnections":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CAPT_CL_CONN \$ARG2$";
    "check_tc-net-server_capturingserverconnections":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CAPT_SERV_CONN \$ARG2$";
    "check_tc-net-server_capturingthroughput":
      command_line => "/usr/bin/perl \$USER1$/check_tc-net-server   --host \$HOSTADDRESS$ --instances \$ARG1$ --statistic CAPT_THR \$ARG2$";
  }

}

class icinga::nagios-plugins-load {

  include icinga::nagios-plugins-nrpe

  package {
    "nagios-plugins-load":
      ensure => installed;
  }

  nagios_command {
    "check_load":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_load -a 15,10,5 30,25,20";
  }

}

class icinga::nagios-plugins-users {

  include icinga::nagios-plugins-nrpe

  package {
    "nagios-plugins-users":
      ensure => installed;
  }

  nagios_command {
    "check_users":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_users -a 5 10";
  }

}

class icinga::nagios-plugins-procs {

  include icinga::nagios-plugins-nrpe

  package {
    "nagios-plugins-procs":
      ensure => installed;
  }

  nagios_command {
    "check_procs":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_procs -a 250 300";
  }

}

class icinga::nagios-plugins-swap {

  include icinga::nagios-plugins-nrpe

  package {
    "nagios-plugins-swap":
      ensure => installed;
  }

  nagios_command {
    "check_swap":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_swap -a 20 10";
  }

}

class icinga::nagios-plugins-ping {

  include icinga::nagios-plugins-nrpe

  nagios_command {
    "check_ping_remote":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_ping  -t 30 -a \$ARG1$";
    "check_ping6_remote":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_ping6 -t 30 -a \$ARG1$";
  }

}

class icinga::nagios-plugins-nrpe {

  include icinga

  package {
    "nagios-plugins-nrpe":
      ensure => installed;
  }

  nagios_command {
    "check_nrpe":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$";
  }

}

class icinga::nagios-plugins-file_age {

  include icinga::nagios-plugins-nrpe

  nagios_command {
    "check_file_age":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_file_age -a \$ARG1$ \$ARG2$ \$ARG3$ \$ARG4$ \$ARG5$ ";
  }

}

class icinga::nagios-plugins-hpbladechassis {

  include icinga

  package {
    "nagios-plugins-hpbladechassis":
      ensure => installed;
  }

  nagios_command {
    "check_hp_bladechassis":
      command_line => "/usr/bin/perl \$USER1$/check_hp_bladechassis -H \$HOSTADDRESS$ --port 10601 -C public --perfdata";
  }

}

class icinga::nagios-plugins-nrpe-tellitec {

  include icinga::nagios-plugins-nrpe

  nagios_command {
    "check_tc-shape-server_shaping-ratio":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_tc-shape-server_shaping-ratio -a \$ARG1$ \$ARG2$";
  }

}

class icinga::nagios-plugins-hpasm {

  include icinga::nagios-plugins-nrpe

  nagios_command {
    "check_hpasm":
      command_line => "\$USER1$/check_nrpe -H \$HOSTADDRESS$ -c check_hpasm";
  }

}
