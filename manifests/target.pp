class icinga::target {

  @@nagios_host { ${hostname}:
    use        => 'ntc-host',
    hostgroups => 'linux',
    tag        => 'icinga';
  }

}
