# @summary Setup some basic changes for an xdmod server 
#
# Setup xdmod server to allow transfers from xdmod client, this class does not install or configure the xdmod service itself
#
# @param additional_sshd_match_params
#   Hash of additional sshd match parameters.
#   Passed to `sshd::allow_from` defined type from `profile_xdmod::server::allow_client`.
#
# @param clients
#   This is a hash that contains all the parameters for `profile_xdmod::server::allow_client`:
#   ```yaml
#   profile_xdmod::server::clients:
#     fqdn-of-client:
#       ip: "172.1.2.3"
#       ssh_key_pub: "AAAAB..."  # PUBLIC KEY
#       ssh_key_type: "ssh-rsa"  # ENCRYPTION TYPE
#   ```
#
# @param gid
#   Group id of user that owns xdmod report files.
#
# @param groupname
#   Groupname that owns xdmod report files.
#
# @param slurm_log_parent_dir
#   Parent directory path where Slurm logs to be shredded are stored
#
# @param uid
#   User id of user that owns xdmod report files.
#
# @param username
#   Username that owns xdmod report files and allowed access.
#
# @example
#   include profile_xdmod::server
class profile_xdmod::server (
  Hash    $additional_sshd_match_params,
  Hash    $clients,
  Integer $gid,
  String  $groupname,
  String  $slurm_log_parent_dir,
  Integer $uid,
  String  $username,
) {
  $dir_defaults = {
    ensure => directory,
    group  => $gid,
    owner  => $uid,
  }

  # SETUP service account USER & GROUP
  group { $groupname:
    ensure     => 'present',
    forcelocal => true,
    gid        => $gid,
  }

  user { $username:
    ensure     => 'present',
    uid        => $uid,
    forcelocal => true,
    gid        => $gid,
    groups     => [$groupname],
    home       => $slurm_log_parent_dir,
    password   => '!!',
    shell      => '/sbin/nologin',
    comment    => 'NCSA xdmod',
  }

  $clients.each |$key, $value| {
    profile_xdmod::server::allow_client { $key: * => $value }
  }
}
