#WARNING - WILL DISABLE DHCP ON INTERFACES OF THE ADDRESSFAMILY
#WARNING - ONLY USE THIS WHEN YOU HAVE ONE NETWORK ADAPTER
#manage IP addresses on a nic - note no ability to manage multiple nics - requires 1 nic and no more
define netadapter_singleint::staticip($ipaddress = $title, $addressfamily = 'ipv4', $prefixlength = '24', $casttype = 'unicast', $ensure = 'present', $dnsclientservers, $defaultgateway) {

  validate_re($ipaddress, ['^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$'])
  validate_re($addressfamily, ['^(ipv4|ipv6)$'],'addressfamily must be one of \'ipv4\', \'ipv6\'')
  validate_re($casttype, '^(unicast|anycast)$', 'casttype must be one of \'unicast\', \'anycast\'')
  validate_re($ensure, '^(present|add|absent|remove|delete)$', 'ensure must be one of \'present\', \'add\', \'absent\', \'remove\', \'delete\'')
  validate_re($defaultgateway, ['^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$'])

#other things require this so we'll get the boot if we have more than one nic, powershell in individual things also checks because obsessive compulsive
    exec { "check for more than one nic - ${title}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}else{exit 0;}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}else{exit 0;}",
      logoutput => true,
    }

  if ($ensure in ['present','add']) {

    exec { "disable DHCP on adapter for '${addressfamily}' - ${ipaddress}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$interfaces = get-netipinterface | where 'dhcp' -eq 'enabled' | where 'addressfamily' -eq '${addressfamily}';if(\$interfaces){\$interfaces | set-netipinterface -dhcp disabled;}else{exit 0;}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$interfaces = get-netipinterface | where 'dhcp' -eq 'enabled' | where 'addressfamily' -eq '${addressfamily}';if(\$interfaces){exit 1;}else{exit 0;}",
      logoutput => true,
      require   => Exec["check for more than one nic - ${title}"],
    }

    exec { "dns client servers - ${title} - ${dnsclientservers}" :
      command   => "Import-Module NetAdapter;[String[]]\$dnsclientservers = (get-netadapter | Get-DnsClientServerAddress -addressfamily IPv4 | select 'serveraddresses').serveraddresses;[String[]]\$a = ${dnsclientservers};[boolean] \$missing = \$false;if(\$dnsclientservers -eq \$null){\$missing = \$true;}else{foreach(\$s in \$a){if(!\$dnsclientservers.Contains(\$s)){\$missing = \$true;break;}}}if(\$missing){get-netadapter | set-DnsClientServerAddress -ServerAddresses \$a;}else {exit 0;}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;[String[]]\$dnsclientservers = (get-netadapter | Get-DnsClientServerAddress -addressfamily IPv4 | select 'serveraddresses').serveraddresses;[String[]]\$a = ${dnsclientservers};[boolean] \$missing = \$false;if(\$dnsclientservers -eq \$null){\$missing = \$true;}elseif(\$a.Length -ne \$dnsclientservers.Length){\$missing = \$true;}else{foreach(\$s in \$a){if(!\$dnsclientservers.Contains(\$s)){\$missing = \$true;break;}}}if(\$missing){exit 1;}else{exit 0;}",
      logoutput => true,
      require   => [Exec["check for more than one nic - ${title}"],Exec["disable DHCP on adapter for '${addressfamily}' - ${ipaddress}"]],
    }

    exec { "Create - ${ipaddress}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{\$adapters | new-netipaddress -addressfamily ${addressfamily} -ipaddress ${ipaddress} -prefixlength ${prefixlength} -type ${casttype};}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{exit 1;}",
      logoutput => true,
      require   => [Exec["check for more than one nic - ${title}"],Exec["disable DHCP on adapter for '${addressfamily}' - ${ipaddress}"]],
    }

    exec { "netmask - ${title} - /${prefixlength}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'prefixlength' -eq '${prefixlength}'| where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{\$adapters | set-netipaddress -prefixlength ${prefixlength};}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'prefixlength' -eq '${prefixlength}'| where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{exit 1;}",
      logoutput => true,
      require   => Exec["Create - ${ipaddress}"],
    }

    #don't really need to manage addressfamily as an ip address IS either ipv4 or ipv6

    exec { "casttype - ${title} - ${casttype}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'type' -eq '${casttype}'| where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{\$adapters | set-netipaddress -type ${casttype};}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'type' -eq '${casttype}'| where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 0;}else{exit 1;}",
      logoutput => true,
      require   => Exec["Create - ${ipaddress}"],
    }

    exec { "default gateway - ${title} - ${defaultgateway}" :
      command   => "Import-Module NetAdapter;\$defaultgateway = '${defaultgateway}';\$nexthop = (get-netadapter | Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop;if(\$nexthop -eq \$null){get-netadapter | new-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop \$defaultgateway -Confirm:\$false;}elseif(\$defaultgateway -ne \$nexthop){Get-NetAdapter | remove-netroute -DestinationPrefix 0.0.0.0/0 -Confirm:\$false;get-netadapter | new-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop \$defaultgateway -Confirm:\$false;}else{exit 0;}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$defaultgateway = '${defaultgateway}';\$nexthop = (get-netadapter | Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop;if(\$nexthop -eq \$null){exit 1;}elseif(\$defaultgateway -ne \$nexthop){exit 1;}else{exit 0;}",
      logoutput => true,
      require   => Exec["Create - ${ipaddress}"],
    }

}
else { #string validation on others is going to be in the 'absent' category
    exec { "Delete - ${ipaddress}" :
      command   => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){\$ipaddress | remove-netipaddress;}else{exit 0;}",
      provider  => powershell,
      unless    => "Import-Module NetAdapter;\$adapters = Get-NetAdapter;if(\$adapters.count -gt 1){exit 1;}\$ipaddress = Get-NetIPAddress |where 'ipaddress' -eq '${ipaddress}';if(\$ipaddress){exit 1;}else{exit 0;}",
      logoutput => true,
      require   => Exec["check for more than one nic - ${title}"], #does not check dhcp state on adapter
    }
  }
}