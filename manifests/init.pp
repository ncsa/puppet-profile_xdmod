# @summary Empty init class
#
# This class should never be included. Depending on the role,
# include one or more of the following:
# - Node generating xdmod reports: `include profile_xdmod::client`
# - Node running xdmod service: `include profile_xdmod::server`
#
# @example
#   include profile_xdmod
class profile_xdmod {
  # THIS CLASS IS INTENTIONALLY LEFT EMPTY

  $notify_text = @("EOT"/)
    The top level profile_xdmod class should not be used.
    Instead use one of the following classes:
      - profile_xdmod::client
      - profile_xdmod::server
    | EOT
  notify { $notify_text:
    withpath => true,
    loglevel => 'warning',
  }
}
