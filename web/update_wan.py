import os
os.chdir('/root/LineHub OS V2开发')
p = 'src/views/network/Wan.vue'
s = open(p, encoding='utf-8').read()

# Replace the wan3 entry (VLAN on eth0 with 3 sessions) -> eth1 with 10 sessions
old = "{ name: 'wan3', device: 'eth0', method: 'VLAN虚拟拨号', status: '已连接',\n    runtime: { ip: '100.64.2.50', gateway: '100.64.2.1', dns: '202.96.128.86', uptime: '3天 1小时', rxRate: '92.5 Mbps', txRate: '28.7 Mbps', latency: '6ms', loss: '0%' },\n    sessions: [\n      { id: 1, vlanId: 100, vlanDevice: 'eth0.100', account: 'vlan_user1@gd', password: 'vlanpass1', status: '已连接', ip: '100.64.2.50', uptime: '3天 1小时' },\n      { id: 2, vlanId: 200, vlanDevice: 'eth0.200', account: 'vlan_user2@gd', password: 'vlanpass2', status: '已连接', ip: '100.64.2.51', uptime: '3天 1小时' },\n      { id: 3, vlanId: 300, vlanDevice: 'eth0.300', account: 'vlan_user3@gd', password: 'vlanpass3', status: '拨号中', ip: '-', uptime: '-' },\n    ]\n  },\n"

new = """{ name: 'wan3', device: 'eth1', method: 'VLAN虚拟拨号', status: '已连接',
    runtime: { ip: '100.64.0.1', gateway: '100.64.0.254', dns: '202.96.128.86', uptime: '5天 2小时', rxRate: '520.5 Mbps', txRate: '280.3 Mbps', latency: '4ms', loss: '0%' },
    sessions: [
      { id: 1, vlanId: 100, vlanDevice: 'eth1.100', account: 'user001@telecom', password: 'pass001', status: '已连接', ip: '100.64.0.10', uptime: '5天 2小时' },
      { id: 2, vlanId: 101, vlanDevice: 'eth1.101', account: 'user002@telecom', password: 'pass002', status: '已连接', ip: '100.64.0.11', uptime: '5天 2小时' },
      { id: 3, vlanId: 102, vlanDevice: 'eth1.102', account: 'user003@telecom', password: 'pass003', status: '已连接', ip: '100.64.0.12', uptime: '4天 15小时' },
      { id: 4, vlanId: 103, vlanDevice: 'eth1.103', account: 'user004@telecom', password: 'pass004', status: '已连接', ip: '100.64.0.13', uptime: '3天 8小时' },
      { id: 5, vlanId: 104, vlanDevice: 'eth1.104', account: 'user005@telecom', password: 'pass005', status: '已连接', ip: '100.64.0.14', uptime: '2天 1小时' },
      { id: 6, vlanId: 105, vlanDevice: 'eth1.105', account: 'user006@telecom', password: 'pass006', status: '已连接', ip: '100.64.0.15', uptime: '1天 12小时' },
      { id: 7, vlanId: 106, vlanDevice: 'eth1.106', account: 'user007@telecom', password: 'pass007', status: '已连接', ip: '100.64.0.16', uptime: '12小时' },
      { id: 8, vlanId: 107, vlanDevice: 'eth1.107', account: 'user008@telecom', password: 'pass008', status: '拨号中', ip: '-', uptime: '-' },
      { id: 9, vlanId: 108, vlanDevice: 'eth1.108', account: 'user009@telecom', password: 'pass009', status: '已连接', ip: '100.64.0.17', uptime: '6小时' },
      { id: 10, vlanId: 109, vlanDevice: 'eth1.109', account: 'user010@telecom', password: 'pass010', status: '已连接', ip: '100.64.0.18', uptime: '2小时' },
    ]
  },
"""

if old not in s:
    print('wan3 old data NOT FOUND, checking partial...')
    # Fall back to replacing just the device line and sessions
    # Actually, let me check what's in the file
    idx = s.find('wan3')
    if idx >= 0:
        print(f'wan3 found at position {idx}')
        print(s[idx:idx+200])
    exit(1)

s = s.replace(old, new, 1)

# Update wan_main entry to be on eth1 too
s = s.replace("{ name: 'wan', device: 'eth2', method: 'PPPoE拨号'", "{ name: 'wan_main', device: 'eth1', method: 'PPPoE拨号'")

open(p, 'w', encoding='utf-8').write(s)
print('Wan.vue updated OK')
