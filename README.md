# karmafeast-netadapter_singleint
windows puppet module network adapter - only supports single interface at the moment
supports server 2012 / windows 8.1+ - need 'netadapter' powershell commandlets

WILL SWITCH OFF DHCP IF YOU HAVE IT ON ON THE NIC AND SET THE THING STATICALLY

hiera example down the bottom

will delete existing routes to 0.0.0.0/0 and add one you specify.

Will fail safely if attempt to use this on node with more than one NIC

should work OK with ipv6, not tested

example use:
class dogfood{
  
  #note the format of the dnsclientservers parameter, it's how the powershell provider wants it
  
  #you can use the IP you want in the 'title' of the resource...
  netadapter_singleint::staticip { '1.2.3.4':
    ensure           => present,
    addressfamily    => 'ipv4',
    prefixlength     => '24',
    casttype         => 'unicast',
    dnsclientservers => "'1.2.2.2','1.3.3.3'",
    defaultgateway   => '1.2.3.1'
  }
   #...or explicitly specify it as parameter
   netadapter_singleint::staticip { 'second IP explicitly defined ipaddress':
    ipaddress        => '1.2.3.5',
    ensure           => present,
    addressfamily    => 'ipv4',
    prefixlength     => '24',
    casttype         => 'unicast',
    dnsclientservers => "'1.2.2.2','1.3.3.3'",
    defaultgateway   => '1.2.3.1',
  }
  
  #defaults - addressfamily => ipv4, prefixlength => 24, casttype => unicast, ensure => present... so...
  netadapter_singleint::staticip { '1.2.3.6':
    dnsclientservers => "'1.2.2.2','1.3.3.3'",
    defaultgateway   => '1.2.3.1',
  }
  
  #wanna remove one?...
    netadapter_singleint::staticip { '1.2.3.7':
    ensure           => absent,
    dnsclientservers => 'this is effectively junk data for ensure => absent',
    defaultgateway   => 'this is effectively junk data for ensure => absent',
  }
  
}

hiera example:
dogfood.yaml - 

---
netadapter_singleinterfaceipadd::ipaddresses:
  1.2.3.8:
    addressfamily: ipv4
    ipaddress: 1.2.3.8
    prefixlength: 24
    dnsclientservers: "'1.2.2.2','1.3.3.3'"
    defaultgateway: 1.2.3.1
    casttype: unicast
  1.2.3.9:
    dnsclientservers: "'1.2.2.2','1.3.3.3'"
    defaultgateway: 1.2.3.1
  1.2.3.10:
    ensure: absent
    dnsclientservers: junkdata
    defaultgateway: junkdata




