# Installs & configure the heat API service

class heat::api (
  $enabled           = true,
  $bind_host         = '0.0.0.0',
  $bind_port         = '8004',
  $workers           = '0',
  $use_ssl           = false,
  $cert_file         = false,
  $key_file          = false,
) {

  include heat
  include heat::params

  Heat_config<||> ~> Service['heat-api']

  Package['heat-api'] -> Heat_config<||>
  Package['heat-api'] -> Service['heat-api']

  if $use_ssl {
    if !$cert_file {
      fail('The cert_file parameter is required when use_ssl is set to true')
    }
    if !$key_file {
      fail('The key_file parameter is required when use_ssl is set to true')
    }
  }

  package { 'heat-api':
    ensure => installed,
    name   => $::heat::params::api_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'heat-api':
    ensure     => $service_ensure,
    name       => $::heat::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['heat-common'],
                  Package['heat-api']],
    subscribe  => Exec['heat-dbsync'],
  }

  heat_config {
    'heat_api/bind_host'  : value => $bind_host;
    'heat_api/bind_port'  : value => $bind_port;
    'heat_api/workers'    : value => $workers;
  }

  # SSL Options
  if $use_ssl {
    heat_config {
      'heat_api/cert_file' : value => $cert_file;
      'heat_api/key_file' :  value => $key_file;
    }
  } else {
    heat_config {
      'heat_api/cert_file' : ensure => absent;
      'heat_api/key_file' :  ensure => absent;
    }
  }

}
