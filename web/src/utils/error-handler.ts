import { ElMessage, ElNotification } from 'element-plus';
import { logger } from './logger';

/**
 * 错误类型枚举
 */
export enum ErrorType {
  // 网络相关错误
  NETWORK_ERROR = 'NETWORK_ERROR',
  API_ERROR = 'API_ERROR',
  TIMEOUT_ERROR = 'TIMEOUT_ERROR',
  
  // SDK相关错误
  SDK_INIT_ERROR = 'SDK_INIT_ERROR',
  SDK_LOGIN_ERROR = 'SDK_LOGIN_ERROR',
  SDK_STREAM_ERROR = 'SDK_STREAM_ERROR',
  
  // 权限相关错误
  PERMISSION_ERROR = 'PERMISSION_ERROR',
  AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
  
  // 业务逻辑错误
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  BUSINESS_ERROR = 'BUSINESS_ERROR',
  
  // 配置错误
  CONFIG_ERROR = 'CONFIG_ERROR',
  
  // 未知错误
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
}

/**
 * 错误严重程度
 */
export enum ErrorSeverity {
  LOW = 'low',       // 轻微错误，不影响主要功能
  MEDIUM = 'medium', // 中等错误，影响部分功能
  HIGH = 'high',     // 严重错误，影响主要功能
  CRITICAL = 'critical', // 致命错误，应用无法继续运行
}

/**
 * 应用错误基类
 */
export class AppError extends Error {
  public readonly type: ErrorType;
  public readonly severity: ErrorSeverity;
  public readonly code?: string | number;
  public readonly context?: any;
  public readonly timestamp: number;
  public readonly canRetry: boolean;
  public readonly userMessage: string;

  constructor(
    message: string,
    type: ErrorType = ErrorType.UNKNOWN_ERROR,
    severity: ErrorSeverity = ErrorSeverity.MEDIUM,
    options?: {
      code?: string | number;
      context?: any;
      canRetry?: boolean;
      userMessage?: string;
    }
  ) {
    super(message);
    this.name = 'AppError';
    this.type = type;
    this.severity = severity;
    this.code = options?.code;
    this.context = options?.context;
    this.timestamp = Date.now();
    this.canRetry = options?.canRetry ?? false;
    this.userMessage = options?.userMessage || this.getDefaultUserMessage();
  }

  private getDefaultUserMessage(): string {
    switch (this.type) {
      case ErrorType.NETWORK_ERROR:
        return '网络连接失败，请检查网络设置';
      case ErrorType.API_ERROR:
        return '服务暂时不可用，请稍后重试';
      case ErrorType.TIMEOUT_ERROR:
        return '请求超时，请稍后重试';
      case ErrorType.SDK_INIT_ERROR:
        return 'SDK 初始化失败，请刷新页面重试';
      case ErrorType.SDK_LOGIN_ERROR:
        return '登录房间失败，请重试';
      case ErrorType.SDK_STREAM_ERROR:
        return '音视频流异常，请检查设备权限';
      case ErrorType.PERMISSION_ERROR:
        return '权限不足，请检查浏览器设置';
      case ErrorType.AUTHENTICATION_ERROR:
        return '认证失败，请重新登录';
      case ErrorType.VALIDATION_ERROR:
        return '输入信息有误，请检查后重试';
      case ErrorType.BUSINESS_ERROR:
        return '操作失败，请稍后重试';
      case ErrorType.CONFIG_ERROR:
        return '配置错误，请联系管理员';
      default:
        return '操作失败，请稍后重试';
    }
  }
}

/**
 * 错误处理配置
 */
interface ErrorHandlerConfig {
  showNotification: boolean;
  logError: boolean;
  reportError: boolean;
  enableRetry: boolean;
  maxRetries: number;
  retryDelay: number;
}

/**
 * 统一错误处理器
 */
export class ErrorHandler {
  private static config: ErrorHandlerConfig = {
    showNotification: true,
    logError: true,
    reportError: false, // 暂时关闭错误上报
    enableRetry: true,
    maxRetries: 3,
    retryDelay: 1000,
  };

  /**
   * 更新错误处理配置
   */
  static updateConfig(newConfig: Partial<ErrorHandlerConfig>): void {
    this.config = { ...this.config, ...newConfig };
  }

  /**
   * 主要错误处理方法
   */
  static handle(error: any, context?: string): AppError {
    const appError = this.normalizeError(error, context);
    
    // 记录错误日志
    if (this.config.logError) {
      this.logError(appError, context);
    }

    // 显示用户提示
    if (this.config.showNotification) {
      this.showUserNotification(appError);
    }

    // 错误上报（如果需要）
    if (this.config.reportError) {
      this.reportError(appError);
    }

    return appError;
  }

  /**
   * 标准化错误对象
   */
  private static normalizeError(error: any, context?: string): AppError {
    // 如果已经是 AppError，直接返回
    if (error instanceof AppError) {
      return error;
    }

    // HTTP 错误处理
    if (error?.response) {
      return this.handleHttpError(error, context);
    }

    // 网络错误处理
    if (error?.code === 'NETWORK_ERROR' || error?.message?.includes('Network Error')) {
      return new AppError(
        error.message || '网络错误',
        ErrorType.NETWORK_ERROR,
        ErrorSeverity.HIGH,
        { context, canRetry: true }
      );
    }

    // SDK 错误处理
    if (context?.includes('SDK') || context?.includes('zego')) {
      return this.handleSdkError(error, context);
    }

    // 默认错误处理
    return new AppError(
      error?.message || error?.msg || error || '未知错误',
      ErrorType.UNKNOWN_ERROR,
      ErrorSeverity.MEDIUM,
      { context, code: error?.code }
    );
  }

  /**
   * 处理 HTTP 错误
   */
  private static handleHttpError(error: any, context?: string): AppError {
    const status = error.response?.status;
    const data = error.response?.data;

    switch (status) {
      case 400:
        return new AppError(
          data?.message || '请求参数错误',
          ErrorType.VALIDATION_ERROR,
          ErrorSeverity.LOW,
          { context, code: status }
        );
      case 401:
        return new AppError(
          '认证失败，请重新登录',
          ErrorType.AUTHENTICATION_ERROR,
          ErrorSeverity.HIGH,
          { context, code: status }
        );
      case 403:
        return new AppError(
          '权限不足',
          ErrorType.PERMISSION_ERROR,
          ErrorSeverity.MEDIUM,
          { context, code: status }
        );
      case 404:
        return new AppError(
          '请求的资源不存在',
          ErrorType.API_ERROR,
          ErrorSeverity.LOW,
          { context, code: status }
        );
      case 429:
        return new AppError(
          '请求过于频繁，请稍后重试',
          ErrorType.API_ERROR,
          ErrorSeverity.MEDIUM,
          { context, code: status, canRetry: true }
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return new AppError(
          '服务器错误，请稍后重试',
          ErrorType.API_ERROR,
          ErrorSeverity.HIGH,
          { context, code: status, canRetry: true }
        );
      default:
        return new AppError(
          data?.message || `请求失败 (${status})`,
          ErrorType.API_ERROR,
          ErrorSeverity.MEDIUM,
          { context, code: status }
        );
    }
  }

  /**
   * 处理 SDK 错误
   */
  private static handleSdkError(error: any, context?: string): AppError {
    const message = error?.message || '未知 SDK 错误';
    
    if (message.includes('login') || message.includes('登录')) {
      return new AppError(
        message,
        ErrorType.SDK_LOGIN_ERROR,
        ErrorSeverity.HIGH,
        { context, canRetry: true }
      );
    }

    if (message.includes('stream') || message.includes('流')) {
      return new AppError(
        message,
        ErrorType.SDK_STREAM_ERROR,
        ErrorSeverity.MEDIUM,
        { context, canRetry: true }
      );
    }

    if (message.includes('init') || message.includes('初始化')) {
      return new AppError(
        message,
        ErrorType.SDK_INIT_ERROR,
        ErrorSeverity.CRITICAL,
        { context, canRetry: false }
      );
    }

    return new AppError(
      message,
      ErrorType.UNKNOWN_ERROR,
      ErrorSeverity.MEDIUM,
      { context }
    );
  }

  /**
   * 记录错误日志
   */
  private static logError(error: AppError, context?: string): void {
    const logData = {
      type: error.type,
      severity: error.severity,
      message: error.message,
      userMessage: error.userMessage,
      code: error.code,
      context: context || error.context,
      timestamp: error.timestamp,
      stack: error.stack,
    };

    switch (error.severity) {
      case ErrorSeverity.CRITICAL:
        logger.error('ERROR_HANDLER', error, logData);
        break;
      case ErrorSeverity.HIGH:
        logger.error('ERROR_HANDLER', error, logData);
        break;
      case ErrorSeverity.MEDIUM:
        logger.warn('ERROR_HANDLER', error.message, logData);
        break;
      case ErrorSeverity.LOW:
        logger.info('ERROR_HANDLER', error.message, logData);
        break;
    }
  }

  /**
   * 显示用户提示
   */
  private static showUserNotification(error: AppError): void {
    const options = {
      duration: this.getNotificationDuration(error.severity),
      showClose: true,
    };

    switch (error.severity) {
      case ErrorSeverity.CRITICAL:
        ElNotification.error({
          title: '严重错误',
          message: error.userMessage,
          ...options,
          duration: 0, // 不自动关闭
        });
        break;
      case ErrorSeverity.HIGH:
        ElMessage.error({
          message: error.userMessage,
          ...options,
        });
        break;
      case ErrorSeverity.MEDIUM:
        ElMessage.warning({
          message: error.userMessage,
          ...options,
        });
        break;
      case ErrorSeverity.LOW:
        ElMessage.info({
          message: error.userMessage,
          ...options,
        });
        break;
    }
  }

  /**
   * 获取通知显示时长
   */
  private static getNotificationDuration(severity: ErrorSeverity): number {
    switch (severity) {
      case ErrorSeverity.CRITICAL:
        return 0; // 不自动关闭
      case ErrorSeverity.HIGH:
        return 5000;
      case ErrorSeverity.MEDIUM:
        return 3000;
      case ErrorSeverity.LOW:
        return 2000;
      default:
        return 3000;
    }
  }

  /**
   * 错误上报（预留接口）
   */
  private static reportError(error: AppError): void {
    // 这里可以集成错误监控服务，如 Sentry
    if (import.meta.env.MODE === 'development') {
      logger.debug('ERROR_REPORTER', '错误上报', {
        type: error.type,
        message: error.message,
        severity: error.severity,
        timestamp: error.timestamp,
      });
    }
  }

  /**
   * 带重试的异步操作包装器
   */
  static async withRetry<T>(
    operation: () => Promise<T>,
    context?: string,
    maxRetries?: number
  ): Promise<T> {
    const retries = maxRetries ?? this.config.maxRetries;
    let lastError: any;

    for (let attempt = 1; attempt <= retries + 1; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        
        const appError = this.normalizeError(error, context);
        
        // 如果不能重试或者已经是最后一次尝试，抛出错误
        if (!appError.canRetry || attempt > retries) {
          throw this.handle(error, context);
        }

                 // 等待后重试
         await this.delay(this.config.retryDelay * attempt);
         logger.warn('ERROR_HANDLER', `重试操作 (${attempt}/${retries})`, { 
           context, 
           error: error instanceof Error ? error.message : String(error) 
         });
      }
    }

    throw this.handle(lastError, context);
  }

  /**
   * 延迟工具函数
   */
  private static delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * 便捷的错误处理装饰器
 */
export function handleAsyncErrors(target: any, propertyName: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  
  descriptor.value = async function (...args: any[]) {
    try {
      return await originalMethod.apply(this, args);
    } catch (error) {
      const context = `${target.constructor.name}.${propertyName}`;
      throw ErrorHandler.handle(error, context);
    }
  };
  
  return descriptor;
}

/**
 * 便捷的创建错误方法
 */
export const createError = {
  network: (message: string, options?: any) => 
    new AppError(message, ErrorType.NETWORK_ERROR, ErrorSeverity.HIGH, options),
  
  api: (message: string, options?: any) => 
    new AppError(message, ErrorType.API_ERROR, ErrorSeverity.MEDIUM, options),
  
  sdk: (message: string, options?: any) => 
    new AppError(message, ErrorType.SDK_INIT_ERROR, ErrorSeverity.HIGH, options),
  
  permission: (message: string, options?: any) => 
    new AppError(message, ErrorType.PERMISSION_ERROR, ErrorSeverity.MEDIUM, options),
  
  validation: (message: string, options?: any) => 
    new AppError(message, ErrorType.VALIDATION_ERROR, ErrorSeverity.LOW, options),
  
  business: (message: string, options?: any) => 
    new AppError(message, ErrorType.BUSINESS_ERROR, ErrorSeverity.MEDIUM, options),
};

export default ErrorHandler; 