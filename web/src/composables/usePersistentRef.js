import { ref, watch } from 'vue'

const PREFIX = 'linehub:'

// 全局写入队列，同一 key 只保留最新一次写入，500ms 内合并
const writeQueue = new Map()
let flushTimer = null

function flushWrite(storageKey, val) {
  try {
    localStorage.setItem(storageKey, JSON.stringify(val))
  } catch (e) {
    console.warn('[linehub] 写入本地存储失败:', storageKey, e)
  }
}

function scheduleWrite(storageKey, val) {
  writeQueue.set(storageKey, val)
  if (flushTimer) return

  flushTimer = setTimeout(() => {
    writeQueue.forEach((v, k) => flushWrite(k, v))
    writeQueue.clear()
    flushTimer = null
  }, 400)
}

/**
 * 持久化 ref：初始值从 localStorage 读取，变化时自动写入（400ms 防抖合并）
 * @param {string} key 唯一 key
 * @param {any} defaultValue 初始默认数据
 * @returns Ref 对象，行为同 vue ref
 */
export function usePersistentRef(key, defaultValue) {
  const storageKey = PREFIX + key
  let initial = defaultValue
  try {
    const stored = localStorage.getItem(storageKey)
    if (stored !== null) {
      initial = JSON.parse(stored)
    }
  } catch (e) {
    console.warn('[linehub] 读取本地存储失败:', storageKey, e)
  }
  const r = ref(initial)
  watch(r, (val) => {
    scheduleWrite(storageKey, val)
  }, { deep: true })
  return r
}

/** 清除指定 key 的本地存储 */
export function clearPersistent(key) {
  try { localStorage.removeItem(PREFIX + key) } catch (e) {}
}

/** 清除所有 linehub:* 的本地存储（重置全部演示数据） */
export function clearAllPersistent() {
  try {
    const keys = Object.keys(localStorage).filter(k => k.startsWith(PREFIX))
    keys.forEach(k => localStorage.removeItem(k))
    return keys.length
  } catch (e) {
    return 0
  }
}

/** 列出所有已持久化的 key */
export function listPersistentKeys() {
  try {
    return Object.keys(localStorage).filter(k => k.startsWith(PREFIX)).map(k => k.slice(PREFIX.length))
  } catch (e) {
    return []
  }
}
