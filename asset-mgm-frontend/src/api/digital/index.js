import request from '@/utils/request'

export const digitalAssetApi = {
  page: (params) => request.get('/digital/assets', { params }),
  getById: (id) => request.get(`/digital/assets/${id}`),
  create: (data) => request.post('/digital/assets', data),
  update: (id, data) => request.put(`/digital/assets/${id}`, data),
  delete: (id) => request.delete(`/digital/assets/${id}`)
}
