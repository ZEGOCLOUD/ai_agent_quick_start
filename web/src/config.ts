/**
 * 应用配置管理
 * 支持环境变量配置，便于多环境部署
 */

// 配置接口定义
export interface AppConfig {
  /** ZEGO SDK 配置 */
  zego: {
    appId: number;
    server: string;
  };
  
  /** API 配置 */
  api: {
    baseUrl: string;
    timeout: number;
  };
  
  /** 数字人配置 */
  digitalHuman: {
    id: string;
    configId: string;
  };
  
  /** 环境配置 */
  env: {
    isDevelopment: boolean;
    isDebug: boolean;
    logLevel: 'debug' | 'info' | 'warn' | 'error';
  };
}

/**
 * 获取必需的环境变量，如果未设置则抛出错误
 */
function getRequiredEnv(key: string): string {
  const value = import.meta.env[key];
  if (!value) {
    throw new Error(`缺少必需的环境变量: ${key}`);
  }
  return value;
}

/**
 * 获取可选的环境变量，如果未设置则使用默认值
 */
function getOptionalEnv(key: string, defaultValue: string): string {
  return import.meta.env[key] || defaultValue;
}

/**
 * 获取数字类型的环境变量
 */
function getNumberEnv(key: string, defaultValue?: number): number {
  const value = import.meta.env[key];
  if (!value) {
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    throw new Error(`缺少必需的环境变量: ${key}`);
  }
  
  const num = parseInt(value, 10);
  if (isNaN(num)) {
    throw new Error(`环境变量 ${key} 必须是一个有效的数字`);
  }
  return num;
}

/**
 * 验证配置的有效性
 */
function validateConfig(config: AppConfig): void {
  // 验证 AppID
  if (config.zego.appId <= 0) {
    throw new Error('ZEGO AppID 必须是一个正整数');
  }
  
  // 验证服务器地址
  if (!config.zego.server.startsWith('wss://') && !config.zego.server.startsWith('ws://')) {
    throw new Error('ZEGO 服务器地址必须是有效的 WebSocket URL');
  }
  
  // 验证 API 基础地址
  try {
    new URL(config.api.baseUrl);
  } catch {
    throw new Error('API 基础地址必须是有效的 URL');
  }
  
  // 验证超时时间
  if (config.api.timeout <= 0) {
    throw new Error('API 超时时间必须是正数');
  }
}

// 构建配置对象
const config: AppConfig = {
  zego: {
    appId: getNumberEnv('VITE_ZEGO_APP_ID'),
    server: getRequiredEnv('VITE_ZEGO_SERVER'),
  },
  
  api: {
    baseUrl: getRequiredEnv('VITE_APP_BASE_URL'),
    timeout: getNumberEnv('VITE_API_TIMEOUT', 30000),
  },
  
  digitalHuman: {
    id: getOptionalEnv('VITE_DIGITAL_HUMAN_ID', '20be9bfb-ef6b-4d63-8c3b-1f20077599c5'),
    configId: getOptionalEnv('VITE_CONFIG_ID', 'web'),
  },
  
  env: {
    isDevelopment: import.meta.env.MODE === 'development',
    isDebug: getOptionalEnv('VITE_DEBUG', 'false') === 'true',
    logLevel: (getOptionalEnv('VITE_LOG_LEVEL', 'warn') as AppConfig['env']['logLevel']),
  },
};

// 验证配置
try {
  validateConfig(config);
} catch (error) {
  console.error('配置验证失败:', error);
  throw error;
}

// 开发模式下输出配置信息（隐藏敏感信息）
if (config.env.isDevelopment && config.env.isDebug) {
  console.log('应用配置加载完成:', {
    zego: {
      appId: '***',
      server: config.zego.server.replace(/\/\/.*@/, '//***@'),
    },
    api: {
      baseUrl: config.api.baseUrl,
      timeout: config.api.timeout,
    },
    digitalHuman: {
      id: config.digitalHuman.id,
      configId: config.digitalHuman.configId,
    },
    env: config.env,
  });
}

export default config;

// 向后兼容的导出（避免破坏现有代码）
export const {
  zego: { appId, server },
  digitalHuman: { id: digitalHumanId, configId },
  api: { baseUrl },
} = config;