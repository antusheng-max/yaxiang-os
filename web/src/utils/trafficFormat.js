export function formatBytes(bytes, digits = 2) {
  const value = Number(bytes) || 0
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
  if (value <= 0) return '0 B'
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1)
  return `${(value / 1024 ** index).toFixed(index === 0 ? 0 : digits)} ${units[index]}`
}

export function formatRate(mbps, digits = 1) {
  const value = Number(mbps) || 0
  return value >= 1000
    ? `${(value / 1000).toFixed(2)} Gbps`
    : `${value.toFixed(digits)} Mbps`
}

export function formatPercent(value, digits = 1) {
  return `${(Number(value) || 0).toFixed(digits)}%`
}

export function formatDuration(seconds) {
  const value = Number(seconds) || 0
  if (value < 60) return `${value}秒`
  if (value < 3600) return `${Math.floor(value / 60)}分${value % 60}秒`
  return `${Math.floor(value / 3600)}时${Math.floor(value % 3600 / 60)}分`
}

export function healthTagType(state) {
  return {
    优秀: 'success',
    良好: 'success',
    一般: 'warning',
    拥塞: 'danger',
    高延迟: 'warning',
    高丢包: 'danger',
    离线: 'info',
  }[state] || 'info'
}

