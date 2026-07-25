import BRAND from '../config/brand.js'

export const INSTALLER_SAFETY = Object.freeze({
  source: 'mock',
  dryRun: true,
  realDiskAccess: false,
})

export const INSTALLATION_STAGES = Object.freeze([
  '检查目标硬盘',
  '清理旧分区信息',
  `写入${BRAND.brandName}系统`,
  '创建配置分区',
  '配置BIOS/UEFI启动',
  '写入首次启动参数',
  '校验系统文件',
  '同步模拟磁盘',
])

export const PHYSICAL_PORT_ROLES = Object.freeze([
  '管理口',
  '宽带入口',
  '服务器出口',
  '普通LAN',
  '未使用',
])

export const MOCK_HARDWARE = Object.freeze({
  hostname: BRAND.gatewayName,
  architecture: 'x86_64',
  cpu: 'Intel(R) Xeon(R) E-2336 @ 2.90GHz / 6核12线程',
  memory: '32 GiB DDR4 ECC',
  bootMode: 'UEFI',
  firmware: `${BRAND.firmwareName} 0.1`,
})

export const MOCK_DISKS = Object.freeze([
  {
    id: 'disk-sda',
    displayNumber: '1',
    model: 'Samsung SSD 870 EVO',
    devicePath: '/dev/sda',
    capacity: '1TB',
    capacityGB: 1000,
    interfaceType: 'SATA SSD',
    serialNumber: 'SAMSUNG-DEMO-870EVO-001',
    partitions: [],
    fileSystems: [],
    containsData: false,
    isCurrentInstallMedia: false,
    selectable: true,
  },
  {
    id: 'disk-sdb',
    displayNumber: '2',
    model: 'INTEL SSD S3510',
    devicePath: '/dev/sdb',
    capacity: '480GB',
    capacityGB: 480,
    interfaceType: 'SATA SSD',
    serialNumber: 'INTEL-DEMO-S3510-002',
    partitions: ['/dev/sdb1 EFI 512MB', '/dev/sdb2 EXT4 120GB', '/dev/sdb3 EXT4 359GB'],
    fileSystems: ['FAT32', 'EXT4'],
    containsData: true,
    isCurrentInstallMedia: false,
    selectable: true,
  },
  {
    id: 'disk-nvme0n1',
    displayNumber: '3',
    model: 'Samsung PM9A3 NVMe',
    devicePath: '/dev/nvme0n1',
    capacity: '1.92TB',
    capacityGB: 1920,
    interfaceType: 'NVMe',
    serialNumber: 'SAMSUNG-DEMO-PM9A3-003',
    partitions: ['/dev/nvme0n1p1 XFS 1.50TB', '/dev/nvme0n1p2 EXT4 420GB'],
    fileSystems: ['XFS', 'EXT4'],
    containsData: true,
    isCurrentInstallMedia: false,
    selectable: true,
  },
  {
    id: 'disk-sdc',
    displayNumber: 'X',
    model: 'SanDisk USB',
    devicePath: '/dev/sdc',
    capacity: '32GB',
    capacityGB: 32,
    interfaceType: 'USB 3.0',
    serialNumber: 'SANDISK-DEMO-INSTALL-004',
    partitions: ['/dev/sdc1 FAT32 4GB', '/dev/sdc2 ISO9660 2.1GB'],
    fileSystems: ['FAT32', 'ISO9660'],
    containsData: true,
    isCurrentInstallMedia: true,
    selectable: false,
  },
])

export const MOCK_NETWORK_INTERFACES = Object.freeze([
  {
    interfaceName: 'enp3s0',
    permanentMac: '00:1b:21:aa:10:01',
    pciAddress: '0000:03:00.0',
    driver: 'ixgbe',
    vendor: 'Intel',
    model: 'X520-DA2',
    linkDetected: true,
    speedMbps: 10000,
    duplex: 'full',
    selectedInitialManagementPort: true,
  },
  {
    interfaceName: 'enp4s0',
    permanentMac: '00:1b:21:aa:10:02',
    pciAddress: '0000:03:00.1',
    driver: 'ixgbe',
    vendor: 'Intel',
    model: 'X520-DA2',
    linkDetected: false,
    speedMbps: 0,
    duplex: 'unknown',
    selectedInitialManagementPort: false,
  },
  {
    interfaceName: 'eno1',
    permanentMac: '3c:ec:ef:20:11:30',
    pciAddress: '0000:06:00.0',
    driver: 'bnxt_en',
    vendor: 'Broadcom',
    model: 'NetXtreme BCM5720',
    linkDetected: true,
    speedMbps: 1000,
    duplex: 'full',
    selectedInitialManagementPort: false,
  },
  {
    interfaceName: 'enp7s0',
    permanentMac: '48:21:0b:72:44:19',
    pciAddress: '0000:07:00.0',
    driver: 'igc',
    vendor: 'Intel',
    model: 'I225-V',
    linkDetected: true,
    speedMbps: 2500,
    duplex: 'full',
    selectedInitialManagementPort: false,
  },
])

export const MOCK_BACKUPS = Object.freeze([
  {
    id: 'backup-usb-1',
    displayNumber: '1',
    name: 'yaxiang-backup-20260720.tar.gz',
    source: 'SanDisk USB',
    createdAt: '2026-07-20 18:30:12',
    managementIpv4: '192.168.8.1',
    prefixLength: 24,
    webPort: 8080,
  },
  {
    id: 'backup-local-1',
    displayNumber: '2',
    name: 'yaxiang-auto-backup.tar.gz',
    source: '本机恢复分区',
    createdAt: '2026-07-18 02:00:00',
    managementIpv4: '10.10.10.1',
    prefixLength: 24,
    webPort: 80,
  },
])

export const DEFAULT_CONSOLE_STATE = Object.freeze({
  managementIpv4: '192.168.3.1',
  prefixLength: 24,
  webPort: 80,
  passwordConfigured: true,
  passwordResetCount: 0,
  uptimeSeconds: 38,
  restoredBackupName: '',
})

export function cloneInstallerData(value) {
  return JSON.parse(JSON.stringify(value))
}

export function getInterfaceStableIdentity(networkInterface) {
  if (!networkInterface) return ''
  return `${networkInterface.permanentMac}|${networkInterface.pciAddress}`
}
