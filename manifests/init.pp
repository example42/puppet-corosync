#
# = Class: corosync
#
# This class installs and manages corosync
#
#
# == Parameters
#
# Refer to https://github.com/stdmod for official documentation
# on the stdmod parameters used
#
class corosync (

  $package_name              = $corosync::params::package_name,
  $package_ensure            = 'present',

  $service_name              = $corosync::params::service_name,
  $service_ensure            = 'running',
  $service_enable            = true,

  $config_file_path          = $corosync::params::config_file_path,
  $config_file_replace       = $corosync::params::config_file_replace,
  $config_file_require       = 'Package[corosync]',
  $config_file_notify        = 'Service[corosync]',
  $config_file_source        = undef,
  $config_file_template      = undef,
  $config_file_content       = undef,
  $config_file_options_hash  = undef,

  $config_dir_path           = $corosync::params::config_dir_path,
  $config_dir_source         = undef,
  $config_dir_purge          = false,
  $config_dir_recurse        = true,

  $dependency_class          = undef,
  $my_class                  = undef,

  $monitor_class             = undef,
  $monitor_options_hash      = { } ,

  $firewall_class            = undef,
  $firewall_options_hash     = { } ,

  $scope_hash_filter         = '(uptime.*|timestamp)',

  $tcp_port                  = undef,
  $udp_port                  = undef,

  ) inherits corosync::params {


  # Class variables validation and management

  validate_bool($service_enable)
  validate_bool($config_dir_recurse)
  validate_bool($config_dir_purge)
  if $config_file_options_hash { validate_hash($config_file_options_hash) }
  if $monitor_options_hash { validate_hash($monitor_options_hash) }
  if $firewall_options_hash { validate_hash($firewall_options_hash) }

  $config_file_owner          = $corosync::params::config_file_owner
  $config_file_group          = $corosync::params::config_file_group
  $config_file_mode           = $corosync::params::config_file_mode

  $manage_config_file_content = default_content($config_file_content, $config_file_template)

  $manage_config_file_notify = pickx($config_file_notify)

  if $package_ensure == 'absent' {
    $manage_service_enable = undef
    $manage_service_ensure = stopped
    $config_dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $manage_service_enable = $service_enable
    $manage_service_ensure = $service_ensure
    $config_dir_ensure = directory
    $config_file_ensure = present
  }


  # Resources managed

  if $corosync::package_name {
    package { $corosync::package_name:
      ensure   => $corosync::package_ensure,
    }
  }

  if $corosync::service_name {
    service { $corosync::service_name:
      ensure     => $corosync::manage_service_ensure,
      enable     => $corosync::manage_service_enable,
    }
  }

  if $::osfamily == 'Debian' {
    $exec_command = $corosync::manage_service_enable ? {
      true  => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
      false => 'sed -i s/START=yes/START=no/ /etc/default/corosync',
    }
    $exec_unless = $corosync::manage_service_enable ? {
      true  => 'grep START=yes /etc/default/corosync',
      false => 'grep START=no /etc/default/corosync',
    }
    exec { 'enable_corosync_service':
      command => $exec_command,
      path    => [ '/bin', '/usr/bin' ],
      unless  => $exec_unless,
      require => Package[$corosync::package_name],
      before  => Service[$corosync::service_name],
    }
  }

  if $corosync::config_file_path {
    file { 'corosync.conf':
      ensure  => $corosync::config_file_ensure,
      path    => $corosync::config_file_path,
      mode    => $corosync::config_file_mode,
      owner   => $corosync::config_file_owner,
      group   => $corosync::config_file_group,
      source  => $corosync::config_file_source,
      content => $corosync::manage_config_file_content,
      notify  => $corosync::manage_config_file_notify,
      require => $corosync::config_file_require,
    }
  }

  if $corosync::config_dir_source {
    file { 'corosync.dir':
      ensure  => $corosync::config_dir_ensure,
      path    => $corosync::config_dir_path,
      source  => $corosync::config_dir_source,
      recurse => $corosync::config_dir_recurse,
      purge   => $corosync::config_dir_purge,
      force   => $corosync::config_dir_purge,
      notify  => $corosync::config_file_notify,
      require => $corosync::config_file_require,
    }
  }


  # Extra classes

  if $corosync::dependency_class {
    include $corosync::dependency_class
  }

  if $corosync::my_class {
    include $corosync::my_class
  }

  if $corosync::monitor_class {
    class { $corosync::monitor_class:
      options_hash => $corosync::monitor_options_hash,
      scope_hash   => {}, # TODO: Find a good way to inject class' scope
    }
  }

  if $corosync::firewall_class {
    class { $corosync::firewall_class:
      options_hash => $corosync::firewall_options_hash,
      scope_hash   => {},
    }
  }

}

