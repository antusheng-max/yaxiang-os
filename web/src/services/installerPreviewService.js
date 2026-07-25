import {
  DEFAULT_CONSOLE_STATE,
  INSTALLATION_STAGES,
  INSTALLER_SAFETY,
  MOCK_BACKUPS,
  MOCK_DISKS,
  MOCK_HARDWARE,
  MOCK_NETWORK_INTERFACES,
  cloneInstallerData,
  getInterfaceStableIdentity,
} from '../models/installerPreview.js'

function mockResponse(data) {
  return Promise.resolve({
    data: cloneInstallerData(data),
    meta: { ...INSTALLER_SAFETY },
  })
}

function formatMockDiskList() {
  return MOCK_DISKS.map((disk) => {
    const name = disk.devicePath.replace('/dev/', '')
    const type = disk.isCurrentInstallMedia ? '安装介质' : 'disk'
    const fileSystem = disk.fileSystems.join(',') || '-'
    return `${name.padEnd(11)} ${disk.capacity.padEnd(7)} ${type.padEnd(8)} ${fileSystem.padEnd(12)} ${disk.model}`
  }).join('\n')
}

function formatMockInterfaces(interfaces) {
  return interfaces.map((item, index) => [
    `${index + 1}: ${item.interfaceName}: <${item.linkDetected ? 'UP,LOWER_UP' : 'NO-CARRIER'}>`,
    `    link/ether ${item.permanentMac}  pci ${item.pciAddress}`,
  ].join('\n')).join('\n')
}

export const installerPreviewService = Object.freeze({
  getSafetyContract() {
    return mockResponse(INSTALLER_SAFETY)
  },

  scanHardware() {
    return mockResponse({
      hardware: MOCK_HARDWARE,
      disks: MOCK_DISKS,
      networkInterfaces: MOCK_NETWORK_INTERFACES,
      backups: MOCK_BACKUPS,
      consoleState: DEFAULT_CONSOLE_STATE,
      installationStages: INSTALLATION_STAGES,
    })
  },

  inspectDisk(displayNumber) {
    const disk = MOCK_DISKS.find(
      (item) => item.displayNumber.toLowerCase() === String(displayNumber).trim().toLowerCase(),
    )
    if (!disk) return mockResponse({ valid: false, reason: '未找到对应编号的硬盘。' })
    if (!disk.selectable) {
      return mockResponse({
        valid: false,
        reason: '当前安装介质受保护，不能作为安装目标。',
        disk,
      })
    }
    return mockResponse({ valid: true, disk })
  },

  createInstallSession(disk) {
    const knownDisk = MOCK_DISKS.find((item) => (
      item.id === disk?.id && item.displayNumber === disk?.displayNumber
    ))
    if (!knownDisk || !knownDisk.selectable || knownDisk.isCurrentInstallMedia) {
      return mockResponse({
        started: false,
        reason: '目标硬盘无效或属于当前安装介质。',
      })
    }
    return mockResponse({
      sessionId: `mock-install-${knownDisk.id}`,
      targetIdentity: `${knownDisk.serialNumber}|${knownDisk.devicePath}`,
      stages: INSTALLATION_STAGES,
      started: true,
    })
  },

  reidentifyInterfaces(interfaces) {
    const detectedNames = ['enp5s0', 'enp5s0f1', 'eno2', 'enp8s0']
    const mappings = interfaces.map((item, index) => ({
      stableIdentity: getInterfaceStableIdentity(item),
      previousInterfaceName: item.interfaceName,
      detectedInterfaceName: detectedNames[index] || item.interfaceName,
      permanentMac: item.permanentMac,
      pciAddress: item.pciAddress,
      driver: item.driver,
      vendor: item.vendor,
      model: item.model,
      matchedBy: 'permanentMac + pciAddress',
    }))
    return mockResponse({ mappings })
  },

  testNetwork(target, consoleState) {
    const normalizedTarget = String(target || '').trim()
    const successful = normalizedTarget !== ''
      && normalizedTarget !== '0.0.0.0'
      && normalizedTarget !== 'unreachable'
    return mockResponse({
      target: normalizedTarget,
      successful,
      managementAddress: `${consoleState.managementIpv4}/${consoleState.prefixLength}`,
      gateway: '192.168.3.254',
      dns: ['223.5.5.5', '119.29.29.29'],
      latencyMs: successful ? 8 : null,
      packetLoss: successful ? '0%' : '100%',
    })
  },

  runMaintenanceCommand(input, context = {}) {
    const command = String(input || '').trim().toLowerCase().replace(/\s+/g, ' ')
    const interfaces = context.networkInterfaces || MOCK_NETWORK_INTERFACES
    const consoleState = context.consoleState || DEFAULT_CONSOLE_STATE
    const managementInterface = interfaces.find((item) => item.selectedInitialManagementPort)

    if (command === 'clear') return mockResponse({ action: 'clear', command, output: '' })
    if (command === 'exit') return mockResponse({ action: 'exit', command, output: '' })

    const outputs = {
      help: [
        '允许的安全命令：help  lsblk  ip link  ethtool  reboot  clear  exit',
        '所有输出均来自浏览器内存，不会执行真实Shell命令。',
      ].join('\n'),
      lsblk: [
        'NAME        SIZE    TYPE       FSTYPE       MODEL',
        formatMockDiskList(),
      ].join('\n'),
      'ip link': formatMockInterfaces(interfaces),
      ethtool: [
        `Settings for ${managementInterface?.interfaceName || 'management-port'} (Mock):`,
        `  Speed: ${managementInterface?.speedMbps || 0}Mb/s`,
        `  Duplex: ${managementInterface?.duplex || 'unknown'}`,
        `  Link detected: ${managementInterface?.linkDetected ? 'yes' : 'no'}`,
      ].join('\n'),
      reboot: `模拟重启请求已记录。管理地址仍为 ${consoleState.managementIpv4}。`,
    }

    if (Object.prototype.hasOwnProperty.call(outputs, command)) {
      return mockResponse({ action: 'output', command, output: outputs[command] })
    }

    return mockResponse({
      action: 'output',
      command,
      output: `不允许的命令：${command || '(空)'}\n输入 help 查看安全命令。`,
    })
  },
})
