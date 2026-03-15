<template>
  <div class="home-container">
    <a-layout>
      <a-layout-header class="header">
        <div class="header-content">
          <h1 class="logo">Reader App</h1>
          <div class="user-info">
            <a-avatar :size="32" style="background-color: #87d068">
              <template #icon>
                <UserOutlined />
              </template>
            </a-avatar>
            <span class="username">{{ authStore.userInfo?.displayName || authStore.userInfo?.username }}</span>
            <a-button type="link" @click="handleLogout">退出</a-button>
          </div>
        </div>
      </a-layout-header>

      <a-layout-content class="content">
        <div class="welcome-card">
          <a-result
            status="success"
            title="登录成功！"
            sub-title="欢迎使用 Reader App"
          >
            <template #extra>
              <a-space direction="vertical" :size="16">
                <a-descriptions title="用户信息" bordered :column="1">
                  <a-descriptions-item label="用户ID">
                    {{ authStore.userInfo?.id }}
                  </a-descriptions-item>
                  <a-descriptions-item label="邮箱">
                    {{ authStore.userInfo?.email }}
                  </a-descriptions-item>
                  <a-descriptions-item label="用户名">
                    {{ authStore.userInfo?.username }}
                  </a-descriptions-item>
                  <a-descriptions-item label="显示名称">
                    {{ authStore.userInfo?.displayName }}
                  </a-descriptions-item>
                  <a-descriptions-item label="角色">
                    <a-tag v-for="role in authStore.userInfo?.roles" :key="role" color="blue">
                      {{ role }}
                    </a-tag>
                  </a-descriptions-item>
                  <a-descriptions-item label="邮箱验证">
                    <a-tag :color="authStore.userInfo?.emailVerified ? 'success' : 'warning'">
                  {{ authStore.userInfo?.emailVerified ? '已验证' : '未验证' }}
                </a-tag>
                  </a-descriptions-item>
                  <a-descriptions-item label="账号状态">
                <a-tag :color="authStore.userInfo?.active ? 'success' : 'error'">
                  {{ authStore.userInfo?.active ? '正常' : '禁用' }}
                </a-tag>
                  </a-descriptions-item>
                </a-descriptions>
              </a-space>
            </template>
          </a-result>
        </div>
      </a-layout-content>
    </a-layout>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { UserOutlined } from '@ant-design/icons-vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const handleLogout = () => {
  authStore.logout()
  message.success('已退出登录')
  router.push('/login')
}
</script>

<style scoped>
.home-container {
  min-height: 100vh;
}

.header {
  background: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  padding: 0;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 64px;
}

.logo {
  font-size: 20px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.username {
  color: #6b7280;
}

.content {
  background: #f5f5f5;
  padding: 24px;
}

.welcome-card {
  max-width: 800px;
  margin: 0 auto;
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}
</style>
