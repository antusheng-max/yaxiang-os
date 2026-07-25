import BRAND from '../config/brand.js'

const wizardMock = {
  ports: [
    { id: 'eth0', name: 'eth0', label: '网口 1', status: '已连接', speed: '1 Gbps', hint: '可用于普通上网设备' },
    { id: 'eth1', name: 'eth1', label: '网口 2', status: '未连接', speed: '1 Gbps', hint: '当前没有检测到网线' },
    { id: 'eth2', name: 'eth2', label: '网口 3', status: '已连接', speed: '2.5 Gbps', hint: '推荐作为宽带入口' },
    { id: 'eth3', name: 'eth3', label: '网口 4', status: '已连接', speed: '10 Gbps', hint: '推荐连接服务器或交换机' },
  ],
  accounts: [
    { id: 1, vlanId: 0, account: 'jx-broadband-01', password: 'demo-pass-01', remark: '宽带 1', ipv4: true, ipv6: true },
    { id: 2, vlanId: 0, account: 'jx-broadband-02', password: 'demo-pass-02', remark: '宽带 2', ipv4: true, ipv6: true },
    { id: 3, vlanId: 0, account: 'jx-broadband-03', password: 'demo-pass-03', remark: '宽带 3', ipv4: true, ipv6: true },
    { id: 4, vlanId: 0, account: 'jx-broadband-04', password: 'demo-pass-04', remark: '宽带 4', ipv4: true, ipv6: true },
    { id: 5, vlanId: 0, account: 'jx-broadband-05', password: 'demo-pass-05', remark: '宽带 5', ipv4: true, ipv6: true },
    { id: 6, vlanId: 0, account: 'jx-broadband-06', password: 'demo-pass-06', remark: '宽带 6', ipv4: true, ipv6: true },
  ],
  accessModes: [
    {
      id: 'pppoe',
      name: '宽带账号拨号',
      shortName: 'PPPoE',
      description: '适用于运营商提供了宽带账号和密码的场景，支持一次添加多条线路。',
      recommended: true,
    },
    {
      id: 'dhcp',
      name: '自动获取地址',
      shortName: 'DHCP',
      description: '适用于上级光猫或路由器已经拨号，插上网线即可自动获取地址的场景。',
      recommended: false,
    },
    {
      id: 'static',
      name: '使用固定地址',
      shortName: '静态 IP',
      description: '适用于运营商或机房提供了固定 IP、网关和 DNS 的专线场景。',
      recommended: false,
    },
  ],
  dhcp: {
    vlanId: 0,
    hostname: BRAND.gatewayName,
    ipv4: true,
    ipv6: true,
    dnsMode: 'auto',
    primaryDns: '223.5.5.5',
    secondaryDns: '119.29.29.29',
  },
  staticIp: {
    vlanId: 0,
    ipv4Address: '192.0.2.10',
    ipv4PrefixLength: 24,
    ipv4Gateway: '192.0.2.1',
    primaryDns: '223.5.5.5',
    secondaryDns: '1.1.1.1',
    ipv6: true,
    ipv6Address: '2001:db8:200::10',
    ipv6PrefixLength: 64,
    ipv6Gateway: '2001:db8:200::1',
  },
  detection: {
    uplinkPort: 'eth2',
    lanPort: 'eth3',
    recommendedMode: 'pppoe',
    confidence: 96,
    findings: [
      { label: '宽带入口', value: 'eth2', detail: '检测到运营商设备和 PPPoE 服务响应' },
      { label: '服务器出口', value: 'eth3', detail: '10 Gbps 链路，适合连接服务器或核心交换机' },
      { label: '上网方式', value: 'PPPoE', detail: '检测到未打标签的拨号服务，VLAN ID 为 0' },
      { label: '双栈能力', value: 'IPv4 + IPv6', detail: '建议同时启用 IPv4 与 IPv6' },
    ],
  },
  aggregationModes: [
    {
      id: 'smart',
      name: '智能汇聚',
      description: '自动参考线路质量和负载，为新连接选择更合适的宽带。',
      recommended: true,
    },
    {
      id: 'balanced',
      name: '平均分配',
      description: '尽量平均地把新连接分配到所有可用宽带。',
      recommended: false,
    },
    {
      id: 'failover',
      name: '主备模式',
      description: '平时使用主线路，主线路异常时再切换到备用线路。',
      recommended: false,
    },
  ],
  defaults: {
    broadbandPort: 'eth2',
    lanPort: 'eth3',
    accessMode: 'pppoe',
    aggregationMode: 'smart',
  },
}

const demoMeta = {
  source: 'mock',
  label: '演示数据',
  demoOnly: true,
  writesSystemConfiguration: false,
}

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

export const quickSetupService = {
  async getWizardData() {
    return {
      data: clone(wizardMock),
      meta: { ...demoMeta },
    }
  },

  async detectNetwork() {
    await new Promise((resolve) => setTimeout(resolve, 500))
    return {
      data: clone(wizardMock.detection),
      meta: { ...demoMeta },
    }
  },

  async saveDemoDraft(configuration) {
    return {
      data: {
        saved: true,
        configuration: clone(configuration),
      },
      meta: { ...demoMeta },
    }
  },
}
