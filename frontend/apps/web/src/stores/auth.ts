import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  username: string
  password: string
  displayName: string
}

export interface AuthResponse {
  success: boolean
  message: string
  data: {
    accessToken: string
    refreshToken: string
    expiresIn: number
    refreshExpiresIn: number
    userId: string
    email: string
    username: string
    displayName: string
  }
  error: string | null
}

export interface UserInfo {
  id: string
  email: string
  username: string
  displayName: string
  avatarUrl: string | null
  bio: string | null
  roles: string[]
  active: boolean
  emailVerified: boolean
}

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref<string | null>(localStorage.getItem('access_token'))
  const refreshToken = ref<string | null>(localStorage.getItem('refresh_token'))
  const userInfo = ref<UserInfo | null>(null)

  const isAuthenticated = computed(() => !!accessToken.value)

  // 设置 Token
  function setTokens(access: string, refresh: string) {
    accessToken.value = access
    refreshToken.value = refresh
    localStorage.setItem('access_token', access)
    localStorage.setItem('refresh_token', refresh)

    // 配置 axios 默认请求头
    axios.defaults.headers.common['Authorization'] = `Bearer ${access}`
  }

  // 清除 Token
  function clearTokens() {
    accessToken.value = null
    refreshToken.value = null
    userInfo.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    delete axios.defaults.headers.common['Authorization']
  }

  // 登录
  async function login(credentials: LoginRequest): Promise<{ success: boolean; message: string }> {
    try {
      const response = await axios.post<AuthResponse>('http://localhost:8080/api/v1/auth/login', credentials)

      if (response.data.success) {
        setTokens(response.data.data.accessToken, response.data.data.refreshToken)
        return { success: true, message: response.data.message }
      } else {
        return { success: false, message: response.data.error || '登录失败' }
      }
    } catch (error: any) {
      return { success: false, message: error.response?.data?.error || '登录失败，请稍后重试' }
    }
  }

  // 注册
  async function register(data: RegisterRequest): Promise<{ success: boolean; message: string }> {
    try {
      console.log('发送注册请求:', data)
      const response = await axios.post<AuthResponse>('http://localhost:8080/api/v1/auth/register', data)
      console.log('注册响应:', response.data)

      if (response.data.success) {
        setTokens(response.data.data.accessToken, response.data.data.refreshToken)
        return { success: true, message: response.data.message }
      } else {
        return { success: false, message: response.data.error || '注册失败' }
      }
    } catch (error: any) {
      console.error('注册错误:', error)
      console.error('错误详情:', error.response?.data)
      return { success: false, message: error.response?.data?.error || '注册失败，请稍后重试' }
    }
  }

  // 获取用户信息
  async function getUserInfo(): Promise<boolean> {
    try {
      const response = await axios.get<{ success: boolean; data: UserInfo }>(
        'http://localhost:8080/api/v1/auth/me'
      )

      if (response.data.success) {
        userInfo.value = response.data.data
        return true
      }
      return false
    } catch (error) {
      return false
    }
  }

  // 登出
  function logout() {
    clearTokens()
  }

  // 初始化（从 localStorage 恢复）
  function init() {
    const access = localStorage.getItem('access_token')
    if (access) {
      accessToken.value = access
      axios.defaults.headers.common['Authorization'] = `Bearer ${access}`
    }
    const refresh = localStorage.getItem('refresh_token')
    if (refresh) {
      refreshToken.value = refresh
    }
  }

  // 初始化时调用
  init()

  return {
    accessToken,
    refreshToken,
    userInfo,
    isAuthenticated,
    setTokens,
    clearTokens,
    login,
    register,
    getUserInfo,
    logout,
    init
  }
})
