function normalizeText(content) {
  return String(content || '').trim()
}

export function buildAssetQrContent(assetId) {
  const id = Number(assetId)
  if (!Number.isFinite(id) || id <= 0) return ''
  return `ASSET_ID:${id}`
}

export function parseAssetIdFromQr(content) {
  const text = normalizeText(content)
  if (!text) return null

  if (/^\d+$/.test(text)) {
    const id = Number(text)
    return Number.isFinite(id) && id > 0 ? id : null
  }

  const canonical = text.match(/^ASSET_ID\s*[:：]\s*(\d+)$/i)
  if (canonical) {
    const id = Number(canonical[1])
    return Number.isFinite(id) && id > 0 ? id : null
  }

  const urlMatch = text.match(/\/physical\/assets\/(\d+)(?:[/?#].*)?$/i)
  if (urlMatch) {
    const id = Number(urlMatch[1])
    return Number.isFinite(id) && id > 0 ? id : null
  }

  try {
    const parsed = JSON.parse(text)
    const id = Number(parsed?.assetId)
    if (Number.isFinite(id) && id > 0) {
      return id
    }
  } catch {
    // no-op
  }

  return null
}

export function normalizeQrText(content) {
  return normalizeText(content).toUpperCase()
}

export function extractAssetNoFromQr(content) {
  const text = normalizeQrText(content)
  if (!text) return null

  const mockQr = text.match(/^QR-(PA-[A-Z0-9-]+)$/i)
  if (mockQr) return mockQr[1]

  if (/^PA-[A-Z0-9-]+$/i.test(text)) {
    return text
  }

  return null
}

