# @summary Enable xdmod clients to copy logs to xdmod server
#
# @param ip
#   ip of xdmod client.
#
# @param ssh_key_pub
#   The public ssh key itself; generally a long string...
#
# @param ssh_key_type
#   The encryption type used in the ssh key.
#
# @example
#   profile_xdmod::server::allow_client { 'allow host hostname access to xdmod server':
#     'ip' => String,
#     'ssh_key_pub' => String,
#     'ssh_key_type' => String,
#   }
define profile_xdmod::server::allow_client (
  String $ip,
  String $ssh_key_pub,
  String $ssh_key_type,
) {
  # SET DEFAULTS FOR CLIENT
  $slurm_log_directory = "${profile_xdmod::server::slurm_log_parent_dir}/${title}"

  $host_uniq_sshd_params = { 'ChrootDirectory' => $slurm_log_directory, }
  $final_match_params = $profile_xdmod::server::additional_sshd_match_params + $host_uniq_sshd_params

  # SETUP SSHD MATCHBLOCK, PAM ACCESS, & FIREWALL FOR CLIENT
  ::sshd::allow_from { $name:
    additional_match_params => $final_match_params,
    hostlist                => [$ip],
    users                   => [$profile_xdmod::server::username],
  }

  # SETUP SSH AUTHORIZED KEY ENTRY FOR CLIENT
  ssh_authorized_key { $title:
    ensure  => present,
    key     => Sensitive($ssh_key_pub),
    options => [
      "from=\"${ip}\"",
      #"command=\"scp serve --restrict-to-path ${slurm_log_directory}\"",
      'restrict',
    ],
    type    => $ssh_key_type,
    user    => $profile_xdmod::server::username,
  }

  # ENSURE parent DIRECTORY FOR THIS CLIENT, must be root owned
  file { $slurm_log_directory:
    ensure => directory,
    group  => 'root',
    mode   => '0755',
    owner  => 'root',
  }

  # ENSURE writable drop directory for host
  file { "${slurm_log_directory}/unprocessed":
    ensure => directory,
    group  => $profile_xdmod::server::gid,
    mode   => '0750',
    owner  => $profile_xdmod::server::uid,
  }

  # ENSURE shred dir for host
  file { "${slurm_log_directory}/shredded":
    ensure => directory,
    group  => 'root',
    mode   => '0750',
    owner  => 'root',
  }

  # ENSURE shred_failed dir for host
  file { "${slurm_log_directory}/shred_failed":
    ensure => directory,
    group  => 'root',
    mode   => '0750',
    owner  => 'root',
  }
}
