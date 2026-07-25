/**
 * 亚象网络操作系统 - 统一API适配层
 *
 * 开发环境: 使用 MockAdapter 提供模拟数据
 * 生产OpenWrt环境: 使用 RealAdapter 接入真实系统后端
 *
 * 构建时通过 VITE_ADAPTER_MODE 环境变量切换:
 *   - VITE_ADAPTER_MODE=mock   (开发默认)
 *   - VITE_ADAPTER_MODE=real   (生产OpenWrt)
 */

import { createMockAdapter } from './mockAdapter.js'
import { createRealAdapter } from './realAdapter.js'

const mode = import.meta.env.VITE_ADAPTER_MODE || 'mock'

let adapter

if (mode === 'real') {
  adapter = createRealAdapter()
} else {
  adapter = createMockAdapter()
}

export default adapter

export { adapter }
export const ADAPTER_MODE = mode

/**
 * 检查接口是否已真实实现
 * @param {string} feature - 功能名称
 * @returns {{ implemented: boolean, source: string, reason?: string }}
 */
export function checkImplementation(feature) {
  return adapter.checkImplementation(feature)
}
