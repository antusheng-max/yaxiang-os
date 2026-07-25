/**
 * 网络API - Mock数据提供
 */

export function getMockInterfaces() {
  return [
    { name: 'eth0', type: 'wan', ip: '192.168.0.100', mac: '00:11:22:33:44:55', status: 'up' },
    { name: 'eth1', type: 'lan', ip: '192.168.1.1', mac: '00:11:22:33:44:56', status: 'up' },
    { name: 'eth2', type: 'lan', ip: '10.10.1.1', mac: '00:11:22:33:44:57', status: 'up' },
  ]
}

export function getMockWanList() {
  return [
    { name: 'wan1', interface: 'eth0', ip: '192.168.0.100', gateway: '192.168.0.1', status: 'connected' },
  ]
}

export function getMockLanList() {
  return [
    { name: 'lan1', interface: 'eth1', ip: '192.168.1.1', dhcp: true, status: 'active' },
    { name: 'lan2', interface: 'eth2', ip: '10.10.1.1', dhcp: false, status: 'active' },
  ]
}

export function getMockVlans() {
  return [
    { id: 10, interface: 'eth0', name: 'vlan-mgmt', status: 'active' },
    { id: 20, interface: 'eth0', name: 'vlan-data', status: 'active' },
  ]
}

export function getMockDhcpLeases() {
  return [
    { hostname: 'pc-01', ip: '192.168.1.100', mac: 'aa:bb:cc:dd:ee:01', expires: '2h' },
    { hostname: 'phone-01', ip: '192.168.1.101', mac: 'aa:bb:cc:dd:ee:02', expires: '4h' },
  ]
}
