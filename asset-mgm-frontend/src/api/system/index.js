import request from '@/utils/request'

export const authApi = {
  login: (data) => request.post('/auth/login', data)
}

export const projectApi = {
  page: (params) => request.get('/projects', { params }),
  getById: (id) => request.get(`/projects/${id}`),
  create: (data) => request.post('/projects', data),
  update: (id, data) => request.put(`/projects/${id}`, data),
  delete: (id) => request.delete(`/projects/${id}`)
}

export const userApi = {
  page: (params) => request.get('/system/users', { params }),
  all: () => request.get('/system/users/all'),
  create: (data) => request.post('/system/users', data),
  update: (id, data) => request.put(`/system/users/${id}`, data),
  toggleStatus: (id, status) => request.put(`/system/users/${id}/status`, null, { params: { status } }),
  delete: (id) => request.delete(`/system/users/${id}`)
}

export const roleApi = {
  list: () => request.get('/system/roles'),
  create: (data) => request.post('/system/roles', data),
  update: (id, data) => request.put(`/system/roles/${id}`, data),
  delete: (id) => request.delete(`/system/roles/${id}`)
}

export const locationApi = {
  tree: () => request.get('/system/locations/tree'),
  page: (params) => request.get('/system/locations', { params }),
  create: (data) => request.post('/system/locations', data),
  update: (id, data) => request.put(`/system/locations/${id}`, data),
  delete: (id) => request.delete(`/system/locations/${id}`)
}

export const reportApi = {
  dashboard: () => request.get('/report/dashboard')
}
