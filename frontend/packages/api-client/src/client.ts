import axios, { AxiosInstance, AxiosRequestConfig, AxiosError } from 'axios';
import { API_ENDPOINTS, STORAGE_KEYS, APP_CONFIG } from '@reader-app/shared';

/**
 * API Client configuration
 */
export interface ApiClientConfig {
  baseURL?: string;
  timeout?: number;
  getToken?: () => string | null;
  refreshToken?: () => Promise<string | null>;
  onUnauthorized?: () => void;
}

/**
 * API Client class
 */
export class ApiClient {
  private client: AxiosInstance;
  private getToken?: () => string | null;
  private refreshToken?: () => Promise<string | null>;
  private isRefreshing = false;
  private failedQueue: Array<{
    resolve: (value?: any) => void;
    reject: (reason?: any) => void;
  }> = [];

  constructor(config: ApiClientConfig = {}) {
    this.getToken = config.getToken;
    this.refreshToken = config.refreshToken;

    this.client = axios.create({
      baseURL: config.baseURL || APP_CONFIG.API_BASE_URL,
      timeout: config.timeout || APP_CONFIG.API_TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors(config.onUnauthorized);
  }

  /**
   * Setup request and response interceptors
   */
  private setupInterceptors(onUnauthorized?: () => void) {
    // Request interceptor
    this.client.interceptors.request.use(
      config => {
        const token = this.getToken?.();
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      error => Promise.reject(error)
    );

    // Response interceptor
    this.client.interceptors.response.use(
      response => response,
      async (error: AxiosError) => {
        const originalRequest = error.config as AxiosRequestConfig & {
          _retry?: boolean;
        };

        // Handle 401 Unauthorized
        if (error.response?.status === 401 && !originalRequest._retry) {
          if (this.isRefreshing) {
            // Add to queue if already refreshing
            return new Promise((resolve, reject) => {
              this.failedQueue.push({ resolve, reject });
            })
              .then(token => {
                if (originalRequest.headers) {
                  originalRequest.headers.Authorization = `Bearer ${token}`;
                }
                return this.client(originalRequest);
              })
              .catch(err => Promise.reject(err));
          }

          originalRequest._retry = true;
          this.isRefreshing = true;

          try {
            const newToken = await this.refreshToken?.();
            if (newToken) {
              // Process queue
              this.failedQueue.forEach(({ resolve }) => resolve(newToken));
              this.failedQueue = [];

              // Retry original request
              if (originalRequest.headers) {
                originalRequest.headers.Authorization = `Bearer ${newToken}`;
              }
              return this.client(originalRequest);
            } else {
              // No new token, trigger unauthorized
              this.failedQueue.forEach(({ reject }) => reject(error));
              this.failedQueue = [];
              onUnauthorized?.();
              return Promise.reject(error);
            }
          } catch (refreshError) {
            // Refresh failed
            this.failedQueue.forEach(({ reject }) => reject(refreshError));
            this.failedQueue = [];
            onUnauthorized?.();
            return Promise.reject(refreshError);
          } finally {
            this.isRefreshing = false;
          }
        }

        return Promise.reject(error);
      }
    );
  }

  /**
   * GET request
   */
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.get<T>(url, config);
    return response.data;
  }

  /**
   * POST request
   */
  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.post<T>(url, data, config);
    return response.data;
  }

  /**
   * PUT request
   */
  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.put<T>(url, data, config);
    return response.data;
  }

  /**
   * PATCH request
   */
  async patch<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.patch<T>(url, data, config);
    return response.data;
  }

  /**
   * DELETE request
   */
  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.delete<T>(url, config);
    return response.data;
  }

  /**
   * Get the underlying axios instance
   */
  getInstance(): AxiosInstance {
    return this.client;
  }
}

/**
 * Default API client instance
 */
let apiClient: ApiClient | null = null;

export const initApiClient = (config: ApiClientConfig) => {
  if (!apiClient) {
    apiClient = new ApiClient(config);
  }
  return apiClient;
};

export const getApiClient = () => {
  if (!apiClient) {
    throw new Error('API client not initialized. Call initApiClient first.');
  }
  return apiClient;
};
