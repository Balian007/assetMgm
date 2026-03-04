import request from '@/utils/request'

export const physicalAssetApi = {
  page: (params) => request.get('/physical/assets', { params }),
  getById: (id) => request.get(`/physical/assets/${id}`),
  create: (data) => request.post('/physical/assets', data),
  update: (id, data) => request.put(`/physical/assets/${id}`, data),
  delete: (id) => request.delete(`/physical/assets/${id}`),
  updateStatus: (id, status, reason) => request.put(`/physical/assets/${id}/status`, null, { params: { status, reason } })
}

export const inspectionApi = {
  pageTasks: (params) => request.get('/physical/inspections/tasks', { params }),
  createTask: (data) => request.post('/physical/inspections/tasks', data),
  updateTask: (id, data) => request.put(`/physical/inspections/tasks/${id}`, data),
  deleteTask: (id) => request.delete(`/physical/inspections/tasks/${id}`),
  checkIn: (data) => request.post('/physical/inspections/checkin', data),
  getByAsset: (assetId) => request.get(`/physical/inspections/records/asset/${assetId}`),
  getByTask: (taskId) => request.get(`/physical/inspections/records/task/${taskId}`)
}

export const maintenanceApi = {
  page: (params) => request.get('/physical/maintenance', { params }),
  create: (data) => request.post('/physical/maintenance', data),
  update: (id, data) => request.put(`/physical/maintenance/${id}`, data),
  complete: (id, data) => request.put(`/physical/maintenance/${id}/complete`, data),
  delete: (id) => request.delete(`/physical/maintenance/${id}`)
}

export const inventoryApi = {
  page: (params) => request.get('/physical/inventory', { params }),
  create: (data) => request.post('/physical/inventory', data),
  update: (id, data) => request.put(`/physical/inventory/${id}`, data),
  delete: (id) => request.delete(`/physical/inventory/${id}`),
  getDetails: (taskId) => request.get(`/physical/inventory/${taskId}/details`),
  submitDetail: (taskId, data) => request.post(`/physical/inventory/${taskId}/details`, data)
}
