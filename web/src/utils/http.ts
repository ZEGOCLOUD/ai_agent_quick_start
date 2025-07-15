import axios from 'axios';
import type { AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'
import config from '../config';
import { ErrorHandler, ErrorType, createError } from './error-handler';
import { logger } from './logger';

// 创建axios实例
const service = axios.create({
  baseURL: config.api.baseUrl,
  timeout: config.api.timeout,
  headers: {
    'Content-Type': 'application/json;charset=utf-8',
  },
});

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    // 记录API请求
    logger.apiCall(config.method?.toUpperCase() || 'GET', config.url || '', config.params || config.data);
    
    // 在发送请求之前做些什么，例如添加token
    const token = localStorage.getItem('token');
    if (token) {
      config.headers = config.headers || {};
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error: AxiosError) => {
    // 对请求错误做些什么
    const appError = ErrorHandler.handle(error, 'HTTP_REQUEST');
    return Promise.reject(appError);
  }
);

// 响应拦截器
service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { data } = response;
    
    // 记录API响应
    logger.apiCall(
      response.config.method?.toUpperCase() || 'GET', 
      response.config.url || '', 
      response.config.params || response.config.data,
      { status: response.status, data: data }
    );
    
    // 根据自定义错误码判断请求是否成功
    if (data.code && data.code !== 0) {
      // 处理业务错误 - 不显示通知，让上层处理
      const businessError = createError.business(data.message || '业务操作失败', {
        code: data.code,
        canRetry: false,
        context: 'HTTP_RESPONSE'
      });
      
      return Promise.reject(businessError);
    }
    
    return data;
  },
  (error: AxiosError) => {
    // 使用统一错误处理器处理HTTP错误，但禁用自动通知
    const originalConfig = ErrorHandler['config'];
    ErrorHandler.updateConfig({ showNotification: false });
    
    try {
      const appError = ErrorHandler.handle(error, 'HTTP_RESPONSE');
      // 恢复配置
      ErrorHandler.updateConfig(originalConfig);
      
      // 对于401错误，清除token
      if (error.response?.status === 401) {
        localStorage.removeItem('token');
      }
      
      return Promise.reject(appError);
    } catch (handlerError) {
      // 恢复配置
      ErrorHandler.updateConfig(originalConfig);
      throw handlerError;
    }
  }
);

// 封装GET请求
export function get<T>(url: string, params?: any, config?: AxiosRequestConfig): Promise<T> {
  return service.get(url, { params, ...config });
}

// 封装POST请求
export function post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
  return service.post(url, data, config);
}

// 带重试的GET请求
export function getWithRetry<T>(
  url: string, 
  params?: any, 
  config?: AxiosRequestConfig,
  maxRetries?: number
): Promise<T> {
  return ErrorHandler.withRetry(
    () => service.get(url, { params, ...config }),
    `GET ${url}`,
    maxRetries
  );
}

// 带重试的POST请求
export function postWithRetry<T>(
  url: string, 
  data?: any, 
  config?: AxiosRequestConfig,
  maxRetries?: number
): Promise<T> {
  return ErrorHandler.withRetry(
    () => service.post(url, data, config),
    `POST ${url}`,
    maxRetries
  );
}

// 导出axios实例
export default service;