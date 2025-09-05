# @summary Sets up collecting and transferring Slurm jobs to an xdmod server
#
# @param cron_hour
#   Hour at which to run the xdmod_report cron
#
# @param cron_minute
#   Minute at which to run the xdmod_report cron
#
# @param enable_report_generation
#   Enable or disable the cron which builds the Slurm job report, saving it locally
#
# @param enable_report_transfer
#   Enable or disable the transferring of the Slurm report to the xdmod server. This will only come into effect if `enable_report_generation` is also true
#
# @param report_stage_dir
#   Dir to hold the xdmod reports before copying them to xdmod server
#
# @param ssh_key_priv
#   The private ssh key itself; generally a very long string...
#
# @param ssh_key_pub
#   The public ssh key itself; generally a long string...
#
# @param ssh_key_type
#   The encryption type used in the ssh key.
#
# @param xdmod_dst_dir
#   Dir that client should copy reports to
#
# @param xdmod_hostname
#   xdmod hostname to copy reports to
#
# @param xdmod_service_acct
#   Username of service account used when transferring reports to xdmod server
#
# @example
#   include profile_xdmod::client
class profile_xdmod::client (
  Integer $cron_hour,
  Integer $cron_minute,
  Boolean $enable_report_generation,
  Boolean $enable_report_transfer,
  String  $report_stage_dir,
  String  $ssh_key_priv,
  String  $ssh_key_pub,
  String  $ssh_key_type,
  String  $xdmod_dst_dir,
  String  $xdmod_hostname,
  String  $xdmod_service_acct,
) {
  $sshdir = '/root/.ssh'

  if ($enable_report_generation) {
    $ensure_cron_parm = 'present'
  } else {
    $ensure_cron_parm = 'absent'
  }

  file { '/root/cron_scripts/slurm_xdmod_report.sh':
    ensure  => 'file',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    source  => "puppet:///modules/${module_name}/slurm_xdmod_report.sh",
    require => File['/root/cron_scripts'],
  }

  file { '/root/cron_scripts/slurm_xdmod_transfer_report.sh':
    ensure  => 'file',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    source  => "puppet:///modules/${module_name}/slurm_xdmod_transfer_report.sh",
    require => File['/root/cron_scripts'],
  }

  # Build cfg hash for template
  $report_cfg = {
    report_stage_dir       => $report_stage_dir,
    xdmod_dst_dir          => $xdmod_dst_dir,
    xdmod_hostname         => $xdmod_hostname,
    xdmod_service_acct     => $xdmod_service_acct,
    xdmod_service_acct_key => "${sshdir}/xdmod_${ssh_key_type}",
  }

  file { '/root/cron_scripts/slurm_xdmod_common.config':
    ensure  => 'file',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    content => epp("${module_name}/slurm_xdmod_common.config.epp", $report_cfg),
    require => File['/root/cron_scripts'],
  }

  file { $report_stage_dir:
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  if ($enable_report_transfer) {
    $copy_arg = '--copy'
  } else {
    $copy_arg = ''
  }

  cron { 'slurm_xdmod_report':
    ensure      => $ensure_cron_parm,
    user        => 'root',
    minute      => $cron_minute,
    hour        => $cron_hour,
    month       => '*',
    weekday     => '*',
    monthday    => '*',
    environment => ['SHELL=/bin/sh',],
    command     => "/root/cron_scripts/slurm_xdmod_report.sh ${copy_arg} >/dev/null 2>&1",
  }

  #
  # Key setup
  #
  $ssh_file_defaults = {
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0600',
    require => File[$sshdir],
  }

  $ssh_files = {
    $sshdir => {
      ensure  => directory,
      mode    => '0700',
      require => [],
    },
    "${sshdir}/xdmod_${ssh_key_type}" => {
      content => Sensitive($ssh_key_priv),
    },
    "${sshdir}/xdmod_${ssh_key_type}.pub" => {
      content => Sensitive("${ssh_key_type} ${ssh_key_pub} xdmod_copy@${facts['networking']['fqdn']}\n"),
      mode    => '0640',
    },
  }

  # Ensure the ssh file resources
  ensure_resources( 'file', $ssh_files, $ssh_file_defaults )
}
