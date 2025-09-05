# profile_xdmod

[![pdk-validate](https://github.com/ncsa/puppet-profile_xdmod/actions/workflows/pdk-validate.yml/badge.svg)](https://github.com/ncsa/puppet-profile_xdmod/actions/workflows/pdk-validate.yml)
[![yamllint](https://github.com/ncsa/puppet-profile_xdmod/actions/workflows/yamllint.yml/badge.svg)](https://github.com/ncsa/puppet-profile_xdmod/actions/workflows/yamllint.yml)

NCSA Customizations for xdmod

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with profile_xdmod](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Dependencies](#dependencies)
1. [Reference](#reference)

## Description

Setup a host to be a xdmod client (host which generates report files and transfers them to an xdmod server), or setup a host to be an xdmod server. Note this class does not install or configure the xdmod service itself, it mostly handles config on top that we need for a xdmod server.

## Setup

### xdmod Client Setup

> [!IMPORTANT]  
> For xdmod clients currently this module only supports generating reports for clusters running Slurm

1. Identify the host to be the xdmod client, requirements are:
    - Host can run `sacct` and `scontrol show config` commands
    - Host can reach the xdmod server over the network
1. Generate an SSH key for the client, this can be generated anywhere for now (does not have to be generated from the xdmod client host)
    - If the project uses only RHEL 8 or newer servers, use an ed25519 key type
    - If the project needs to support older OS, use a rsa key type
1. Save SSH private key contents as encrypted eyaml in your projects control repo, see [link](https://wiki.ncsa.illinois.edu/display/PUPPET/Encrypting+Puppet+hiera+with+eyaml#EncryptingPuppethierawitheyaml-EncryptingHieraValueswitheyaml)
    - Typically save this to your project repos `data/secrets/common.eyaml`
    - The specific value will look like this:
    ```yml
    profile_xdmod::client::ssh_key_priv: >
      #LONG ENCRYPTED STRING
    ```
1. Setup xdmod specific values, fine to put these in data/common.yaml
    ```yml
    profile_xdmod::client::ssh_key_pub: "SSH-PUBLIC-KEY-CONTENTS"
    profile_xdmod::client::ssh_key_type: "ssh-ed25519"
    profile_xdmod::client::xdmod_hostname: "FQDN-OF-XDMOD-SERVER-HERE"
    profile_xdmod::client::xdmod_service_acct: "USERNAME-OF-XDMOD-SERVICE-ACCOUNT"
    ```
1. Include the client class for whichever host will be your client (site-modules/role/manifests/YOUR-CLASS-HERE.pp:)
    ```puppet
    include ::profile_xdmod::client
    ```
1. See the steps under [xdmod Server Setup](#xdmod-server-setup) for adding the client to the xdmod server config

### xdmod Server Setup


> [!IMPORTANT]  
> This class does not install or configure the xdmod service itself, it mostly handles config on top that we need for a xdmod server

1. On the project repo that controls the xdmod server, add each client to the clients hash:
    ```yml
    profile_xdmod::server::clients:
      "FQDN-OF-XDMOD-CLIENT":
        ip: "IP-OF-XDMOD-CLIENT"
        ssh_key_pub: "PUBLIC-KEY-CONTENTS-OF-XDMOD-CLIENT"
        ssh_key_type: "ssh-ed25519"
    ```

## Usage

## Dependencies

## Reference

See: [REFERENCE.md](REFERENCE.md)
