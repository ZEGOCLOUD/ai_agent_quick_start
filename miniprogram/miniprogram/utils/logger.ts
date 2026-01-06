/**
 * 统一日志管理工具
 * 提供不同级别的日志输出，方便开发和调试
 */
import envConfig from '../env';

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

class Logger {
  private level: LogLevel;
  private isDevelopment: boolean;

  constructor() {
    this.isDevelopment = envConfig.APP_ENV === 'development';
    this.level = this.isDevelopment ? LogLevel.DEBUG : LogLevel.WARN;
  }

  private formatMessage(level: string, tag: string): string {
    const timestamp = new Date().toLocaleString();
    return `[${timestamp}] [${level}] [${tag}]`;
  }

  debug(tag: string, ...args: any[]) {
    if (this.level <= LogLevel.DEBUG) {
      console.log(this.formatMessage('DEBUG', tag), ...args);
    }
  }

  info(tag: string, ...args: any[]) {
    if (this.level <= LogLevel.INFO) {
      console.info(this.formatMessage('INFO', tag), ...args);
    }
  }

  warn(tag: string, ...args: any[]) {
    if (this.level <= LogLevel.WARN) {
      console.warn(this.formatMessage('WARN', tag), ...args);
    }
  }

  error(tag: string, error: any, ...args: any[]) {
    if (this.level <= LogLevel.ERROR) {
      console.error(this.formatMessage('ERROR', tag), error, ...args);
    }
  }

  /**
   * 记录 API 调用
   */
  apiCall(method: string, url?: string, params?: any, response?: any) {
    this.debug('API', `${method} ${url}`, { params, response });
  }

  /**
   * 记录 WebRTC 事件
   */
  webrtc(event: string, data?: any) {
    this.debug('WebRTC', event, data);
  }

  /**
   * 记录用户操作
   */
  userAction(action: string, data?: any) {
    this.info('USER', action, data);
  }
}

export const logger = new Logger();
export default logger; 