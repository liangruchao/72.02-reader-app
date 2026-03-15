<template>
  <div class="register-container">
    <div class="register-box">
      <div class="register-header">
        <h1>Reader App</h1>
        <p>创建新账号</p>
      </div>

      <a-form
        :model="formState"
        name="register"
        @finish="handleRegister"
        autocomplete="off"
        layout="vertical"
      >
        <a-form-item
          label="邮箱"
          name="email"
          :rules="[
            { required: true, message: '请输入邮箱' },
            { type: 'email', message: '邮箱格式不正确' }
          ]"
        >
          <a-input
            v-model:value="formState.email"
            placeholder="请输入邮箱"
            size="large"
          >
            <template #prefix>
              <MailOutlined />
            </template>
          </a-input>
        </a-form-item>

        <a-form-item
          label="用户名"
          name="username"
          :rules="[
            { required: true, message: '请输入用户名' },
            { min: 3, message: '用户名至少3个字符' },
            { max: 20, message: '用户名最多20个字符' }
          ]"
        >
          <a-input
            v-model:value="formState.username"
            placeholder="请输入用户名"
            size="large"
          >
            <template #prefix>
              <UserOutlined />
            </template>
          </a-input>
        </a-form-item>

        <a-form-item
          label="显示名称"
          name="displayName"
          :rules="[{ required: true, message: '请输入显示名称' }]"
        >
          <a-input
            v-model:value="formState.displayName"
            placeholder="请输入显示名称"
            size="large"
          >
            <template #prefix>
              <IdcardOutlined />
            </template>
          </a-input>
        </a-form-item>

        <a-form-item
          label="密码"
          name="password"
          :rules="[
            { required: true, message: '请输入密码' },
            { min: 6, message: '密码至少6个字符' }
          ]"
        >
          <a-input-password
            v-model:value="formState.password"
            placeholder="请输入密码"
            size="large"
          >
            <template #prefix>
              <LockOutlined />
            </template>
          </a-input-password>
        </a-form-item>

        <a-form-item
          label="确认密码"
          name="confirmPassword"
          :rules="[
            { required: true, message: '请确认密码' },
            { validator: validatePassword }
          ]"
        >
          <a-input-password
            v-model:value="formState.confirmPassword"
            placeholder="请再次输入密码"
            size="large"
          >
            <template #prefix>
              <LockOutlined />
            </template>
          </a-input-password>
        </a-form-item>

        <a-form-item>
          <a-button
            type="primary"
            html-type="submit"
            size="large"
            block
            :loading="loading"
          >
            注册
          </a-button>
        </a-form-item>

        <div class="register-footer">
          <span>已有账号？</span>
          <router-link to="/login">立即登录</router-link>
        </div>
      </a-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import {
  MailOutlined,
  UserOutlined,
  IdcardOutlined,
  LockOutlined
} from '@ant-design/icons-vue'
import { useAuthStore } from '@/stores/auth'
import type { Rule } from 'ant-design-vue/es/form'

const router = useRouter()
const authStore = useAuthStore()

const formState = reactive({
  email: '',
  username: '',
  displayName: '',
  password: '',
  confirmPassword: ''
})

const loading = ref(false)

const validatePassword: Rule = async (_rule, value) => {
  if (value !== formState.password) {
    return Promise.reject('两次输入的密码不一致')
  }
  return Promise.resolve()
}

const handleRegister = async () => {
  loading.value = true
  try {
    const result = await authStore.register({
      email: formState.email,
      username: formState.username,
      displayName: formState.displayName,
      password: formState.password
    })

    if (result.success) {
      message.success('注册成功')
      // 获取用户信息
      await authStore.getUserInfo()
      // 跳转到首页
      router.push('/')
    } else {
      message.error(result.message)
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.register-box {
  width: 400px;
  padding: 40px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
}

.register-header {
  text-align: center;
  margin-bottom: 32px;
}

.register-header h1 {
  font-size: 28px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 8px 0;
}

.register-header p {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

.register-footer {
  text-align: center;
  margin-top: 16px;
  color: #6b7280;
}

.register-footer a {
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
}

.register-footer a:hover {
  text-decoration: underline;
}
</style>
