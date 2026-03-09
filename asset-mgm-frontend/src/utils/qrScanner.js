import { ElMessageBox } from 'element-plus'

export async function scanQrCode() {
  try {
    const { value } = await ElMessageBox.prompt('请输入二维码内容', '扫码', {
      inputPlaceholder: '输入二维码或资产编号'
    })
    return value
  } catch {
    return null
  }
}
