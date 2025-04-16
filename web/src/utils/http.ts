import axios from 'axios';
import type { AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'

// 创建axios实例
const service = axios.create({
  baseURL: '',
  timeout: 15000,  // 请求超时时间
  headers: {
    'Content-Type': 'application/json;charset=utf-8',
  },
});

// 请求拦截器
service.interceptors.request.use(
  (config) => {
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
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

// 响应拦截器
service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { data } = response;
    
    // 根据自定义错误码判断请求是否成功
    if (data.code && data.code !== 200) {
      // 处理业务错误
      const errorMessage = data.message || '未知错误';
      console.error('Business error:', errorMessage);

      return Promise.reject(new Error(errorMessage));
    }
    
    return data;
  },
  (error: AxiosError) => {
    // 处理HTTP错误状态码
    let errorMessage = '网络错误';
    
    if (error.response) {
      const { status } = error.response;
      switch (status) {
        case 401:
          errorMessage = '未授权，请重新登录';
          // 清除token并重定向到登录页
          localStorage.removeItem('token');
          break;
        case 403:
          errorMessage = '拒绝访问';
          break;
        case 404:
          errorMessage = '请求的资源不存在';
          break;
        case 500:
          errorMessage = '服务器内部错误';
          break;
        default:
          errorMessage = `请求错误 (${status})`;
      }
    } else if (error.request) {
      // 请求已发出但未收到响应
      errorMessage = '服务器无响应';
    } else {
      // 请求配置有误
      errorMessage = error.message;
    }
    
    console.error('Response error:', errorMessage);
    return Promise.reject(error);
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

// 导出axios实例
export default service;