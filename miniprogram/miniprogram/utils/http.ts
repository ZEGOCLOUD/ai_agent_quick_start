// http.js
import config from '../config/config';
import { ErrorHandler, createError } from './error-handler';
import { logger } from './logger';

// 基础配置
const baseConfig = {
  baseURL: config.api.baseUrl,
  timeout: config.api.timeout,
  headers: {
    'Content-Type': 'application/json;charset=utf-8',
  },
};

// 请求拦截处理
function handleRequest(config: any) {
  // 记录API请求
  logger.apiCall(
    config.method?.toUpperCase() || 'GET',
    config.url || '',
    config.data || config.params
  );

  // 添加token
  const token = wx.getStorageSync('token');
  if (token) {
    config.header = {
      ...config.header,
      'Authorization': `Bearer ${token}`
    };
  }

  // 处理URL
  if (!config.url.startsWith('http') && baseConfig.baseURL) {
    config.url = baseConfig.baseURL + config.url;
  }

  return config;
}

// 响应拦截处理
function handleResponse(response: any) {
  const { statusCode, data, config } = response;

  // 记录API响应
  logger.apiCall(
    config.method?.toUpperCase() || 'GET',
    config.url || '',
    config.data || config.params,
    { status: statusCode, data }
  );

  // 处理业务错误码
  if (data.code && data.code !== 0) {
    const businessError = createError.business(data.message || '业务操作失败', {
      code: data.code,
      canRetry: false,
      context: 'HTTP_RESPONSE'
    });
    return Promise.reject(businessError);
  }

  return data;
}

// 错误处理
function handleError(error: any, context: string) {
  const originalConfig = ErrorHandler['config'];
  ErrorHandler.updateConfig({ showNotification: false });

  try {
    const appError = ErrorHandler.handle(error, context);
    
    // 处理401错误
    if (error.statusCode === 401) {
      wx.removeStorageSync('token');
    }

    ErrorHandler.updateConfig(originalConfig);
    return Promise.reject(appError);
  } catch (handlerError) {
    ErrorHandler.updateConfig(originalConfig);
    throw handlerError;
  }
}

// 基础请求函数
function request<T>(options: any): Promise<T> {
  return new Promise((resolve, reject) => {
    // 合并配置
    const requestConfig = {
      method: 'GET',
      header: { ...baseConfig.headers },
      timeout: baseConfig.timeout,
      ...options,
    };

    // 请求拦截
    try {
      const processedConfig = handleRequest(requestConfig);
      
      // 发起请求
      wx.request({
        ...processedConfig,
        success: (res) => {
          try {
            const result = handleResponse({
              ...res,
              config: processedConfig
            });
            resolve(result);
          } catch (err) {
            reject(err);
          }
        },
        fail: (err) => {
          // 处理请求失败（网络错误等）
          handleError({ ...err, statusCode: err.statusCode || 0 }, 'HTTP_REQUEST')
            .catch(reject);
        }
      });
    } catch (err) {
      reject(err);
    }
  });
}

// 封装GET请求
export function get<T>(url: string, params?: any, config = {}): Promise<T> {
  return request({
    url,
    method: 'GET',
    data: params, // 小程序GET请求参数放在data里，会自动转为query
    ...config,
  });
}

// 封装POST请求
export function post<T>(url: string, data?: any, config = {}): Promise<T> {
  return request({
    url,
    method: 'POST',
    data,
    ...config,
  });
}

// 重试工具函数
function withRetry(requestFn: any, label: string, maxRetries = 3) {
  let retries = 0;
  
  function attempt() {
    return requestFn().catch((error: any) => {
      retries++;
      if (retries <= maxRetries && ErrorHandler.shouldRetry(error)) {
        logger.apiCall(`重试[${retries}] ${label}`);
        return attempt();
      }
      return Promise.reject(error);
    });
  }
  
  return attempt();
}

// 带重试的GET请求
export function getWithRetry(url: string, params?: any, config = {}, maxRetries = 3) {
  return withRetry(
    () => get(url, params, config),
    `GET ${url}`,
    maxRetries
  );
}

// 带重试的POST请求
export function postWithRetry(url: string, data?: any, config = {}, maxRetries = 3) {
  return withRetry(
    () => post(url, data, config),
    `POST ${url}`,
    maxRetries
  );
}

export default {
  request,
  get,
  post,
  getWithRetry,
  postWithRetry
};