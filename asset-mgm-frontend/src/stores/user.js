import { defineStore } from 'pinia'
import { ref } from 'vue'

function tryDecodeMojibake(text) {
  if (typeof text !== 'string' || !text) return text

  // Typical mojibake markers after UTF-8 bytes are decoded as latin1/cp1252.
  const suspicious = /[ÃÂ�]/.test(text)
  if (!suspicious) return text

  try {
    const decoded = decodeURIComponent(escape(text))
    if (typeof decoded === 'string' && decoded) {
      const bad = s => (s.match(/[ÃÂ�]/g) || []).length
      if (bad(decoded) < bad(text)) return decoded
    }
  } catch {
    // Keep original text when decode fails.
  }

  return text
}

function normalizeUserInfo(raw = {}) {
  return {
    ...raw,
    username: tryDecodeMojibake(raw.username || ''),
    realName: tryDecodeMojibake(raw.realName || '')
  }
}

function readUserInfo() {
  try {
    const parsed = JSON.parse(localStorage.getItem('userInfo') || '{}')
    return normalizeUserInfo(parsed)
  } catch {
    return {}
  }
}

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref(readUserInfo())

  // Persist normalized value to clean up historical garbled cache.
  localStorage.setItem('userInfo', JSON.stringify(userInfo.value))

  function setToken(t) {
    token.value = t
    localStorage.setItem('token', t)
  }

  function setUserInfo(info) {
    userInfo.value = normalizeUserInfo(info)
    localStorage.setItem('userInfo', JSON.stringify(userInfo.value))
  }

  function logout() {
    token.value = ''
    userInfo.value = {}
    localStorage.removeItem('token')
    localStorage.removeItem('userInfo')
  }

  return { token, userInfo, setToken, setUserInfo, logout }
})