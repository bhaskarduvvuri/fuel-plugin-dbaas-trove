#
# Copyright (C) 2016 AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# dbaas_trove::ssl_dns_setup

class dbaas_trove::ssl_dns_setup {

  notice('MODULAR: dbaas_trove/ssl_dns_setup.pp')

  $trove            = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled    = pick($trove['metadata']['enabled'], false)

  $public_ssl_hash = hiera_hash('public_ssl')
  $ssl_hash = hiera_hash('use_ssl', {})
  $public_vip = hiera('public_vip')
  $management_vip = hiera('management_vip')
  $openstack_service_endpoints = hiera_hash('openstack_service_endpoints', {})

  $custom_services = [ 'trove']

  define hosts (
    $ssl_hash,
    ){
    $service = $name
    $public_vip = hiera('public_vip')
    $management_vip = hiera('management_vip')

    $public_hostname = try_get_value($ssl_hash, "${service}_public_hostname", '')
    $internal_hostname = try_get_value($ssl_hash, "${service}_internal_hostname", '')
    $admin_hostname = try_get_value($ssl_hash, "${service}_admin_hostname", $internal_hostname)

    $service_public_ip = try_get_value($ssl_hash, "${service}_public_ip", '')
    if !empty($service_public_ip) {
      $public_ip = $service_public_ip
    } else {
      $public_ip = $public_vip
    }

    $service_internal_ip = try_get_value($ssl_hash, "${service}_internal_ip", '')
    if !empty($service_internal_ip) {
      $internal_ip = $service_internal_ip
    } else {
      $internal_ip = $management_vip
    }

    $service_admin_ip = try_get_value($ssl_hash, "${service}_admin_ip", '')
    if !empty($service_admin_ip) {
      $admin_ip = $service_admin_ip
    } else {
      $admin_ip = $management_vip
    }

    # We always need to set public hostname resolution
    if !empty($public_hostname) and !defined(Host[$public_hostname]) {
      host { $public_hostname:
        name   => $public_hostname,
        ensure => present,
        ip     => $public_ip,
      }
    }

    if ($public_hostname == $internal_hostname) and ($public_hostname == $admin_hostname) {
      notify{"All ${service} hostnames is equal, just public one inserted to DNS":}
    }
    elsif $public_hostanme == $internal_hostname {
      if !empty($admin_hostname) and !defined(Host[$admin_hostname]) {
        host { $admin_hostname:
          name   => $admin_hostname,
          ensure => present,
          ip     => $admin_ip,
        }
      }
    }
    elsif ($public_hostname == $admin_hostname) or ($internal_hostname == $admin_hostname) {
      if !empty($internal_hostname) and !defined(Host[$internal_hostname]) {
        host { $internal_hostname:
          name   => $internal_hostname,
          ensure => present,
          ip     => $internal_ip,
        }
      }
    }
    else {
      if !empty($admin_hostname) and !defined(Host[$admin_hostname]) {
        host { $admin_hostname:
          name   => $admin_hostname,
          ensure => present,
          ip     => $admin_ip,
        }
      }
      if !empty($internal_hostname) and !defined(Host[$internal_hostname]) {
        host { $internal_hostname:
          name   => $internal_hostname,
          ensure => present,
          ip     => $internal_ip,
        }
      }
    }
  }

  if($trove_enabled) {
    if !empty($ssl_hash) {
      hosts { $custom_services:
        ssl_hash => $ssl_hash,
      }
    } elsif !empty($public_ssl_hash) {
      host { $public_ssl_hash['hostname']:
        ensure => present,
        ip     => $public_vip,
      }
    }
  }

}
