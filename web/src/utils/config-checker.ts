/**
 * 配置检查工具
 * 帮助开发者快速诊断配置问题
 */

export interface ConfigCheckResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  suggestions: string[];
}

/**
 * 检查配置的完整性和有效性
 */
export function checkConfig(): ConfigCheckResult {
  const result: ConfigCheckResult = {
    isValid: true,
    errors: [],
    warnings: [],
    suggestions: [],
  };

  // 检查必需的环境变量
  const requiredEnvs = [
    'VITE_ZEGO_APP_ID',
    'VITE_ZEGO_SERVER', 
    'VITE_APP_BASE_URL',
  ];

  for (const envVar of requiredEnvs) {
    if (!import.meta.env[envVar]) {
      result.errors.push(`缺少必需的环境变量: ${envVar}`);
      result.isValid = false;
    }
  }

  // 检查 AppID 格式
  const appId = import.meta.env.VITE_ZEGO_APP_ID;
  if (appId) {
    const numAppId = parseInt(appId, 10);
    if (isNaN(numAppId) || numAppId <= 0) {
      result.errors.push('VITE_ZEGO_APP_ID 必须是一个有效的正整数');
      result.isValid = false;
    }
  }

  // 检查服务器地址格式
  const server = import.meta.env.VITE_ZEGO_SERVER;
  if (server) {
    if (!server.startsWith('wss://') && !server.startsWith('ws://')) {
      result.errors.push('VITE_ZEGO_SERVER 必须是有效的 WebSocket URL (以 wss:// 或 ws:// 开头)');
      result.isValid = false;
    }
  }

  // 检查 API 基础地址
  const baseUrl = import.meta.env.VITE_APP_BASE_URL;
  if (baseUrl) {
    try {
      new URL(baseUrl);
    } catch {
      result.errors.push('VITE_APP_BASE_URL 必须是有效的 URL');
      result.isValid = false;
    }
  }

  // 检查超时时间
  const timeout = import.meta.env.VITE_API_TIMEOUT;
  if (timeout) {
    const numTimeout = parseInt(timeout, 10);
    if (isNaN(numTimeout) || numTimeout <= 0) {
      result.warnings.push('VITE_API_TIMEOUT 应该是一个正整数（毫秒）');
    }
  }

  // 检查调试配置
  const debug = import.meta.env.VITE_DEBUG;
  if (debug && debug !== 'true' && debug !== 'false') {
    result.warnings.push('VITE_DEBUG 应该是 "true" 或 "false"');
  }

  // 检查日志级别
  const logLevel = import.meta.env.VITE_LOG_LEVEL;
  if (logLevel) {
    const validLevels = ['debug', 'info', 'warn', 'error'];
    if (!validLevels.includes(logLevel.toLowerCase())) {
      result.warnings.push(`VITE_LOG_LEVEL 应该是以下值之一: ${validLevels.join(', ')}`);
    }
  }

  // 提供配置建议
  if (!import.meta.env.VITE_DIGITAL_HUMAN_ID) {
    result.suggestions.push('如果需要使用数字人功能，请设置 VITE_DIGITAL_HUMAN_ID');
  }

  if (import.meta.env.MODE === 'production' && import.meta.env.VITE_DEBUG === 'true') {
    result.warnings.push('生产环境建议关闭调试模式 (VITE_DEBUG=false)');
  }

  if (import.meta.env.MODE === 'development' && !import.meta.env.VITE_DEBUG) {
    result.suggestions.push('开发环境建议开启调试模式 (VITE_DEBUG=true)');
  }

  return result;
}

/**
 * 打印配置检查结果
 */
export function printConfigCheckResult(result: ConfigCheckResult): void {
  console.log('📋 配置检查结果');
  console.log('═'.repeat(50));

  if (result.isValid) {
    console.log('✅ 配置验证通过');
  } else {
    console.log('❌ 配置验证失败');
  }

  if (result.errors.length > 0) {
    console.log('\n🚨 错误:');
    result.errors.forEach((error, index) => {
      console.log(`  ${index + 1}. ${error}`);
    });
  }

  if (result.warnings.length > 0) {
    console.log('\n⚠️  警告:');
    result.warnings.forEach((warning, index) => {
      console.log(`  ${index + 1}. ${warning}`);
    });
  }

  if (result.suggestions.length > 0) {
    console.log('\n💡 建议:');
    result.suggestions.forEach((suggestion, index) => {
      console.log(`  ${index + 1}. ${suggestion}`);
    });
  }

  console.log('═'.repeat(50));
}

/**
 * 生成环境变量模板
 */
export function generateEnvTemplate(): string {
  return `# ================================
# AI Agent Web 快速启动配置
# ================================

# ----- 必需配置 -----
# ZEGO Express SDK AppID (从 ZEGO 控制台获取)
VITE_ZEGO_APP_ID=your_appid

# ZEGO 服务器地址
VITE_ZEGO_SERVER=your_server

# 业务后台服务地址 (需要先启动对应的后台服务)
VITE_APP_BASE_URL=your_server_url

# ----- 可选配置 -----
# 数字人ID (如果不使用数字人功能可以保持默认值)
VITE_DIGITAL_HUMAN_ID=20be9bfb-ef6b-4d63-8c3b-1f20077599c5

# 配置ID
VITE_CONFIG_ID=web

# ----- 开发配置 -----
# 是否开启调试模式
VITE_DEBUG=true

# 日志级别 (debug, info, warn, error)
VITE_LOG_LEVEL=debug

# API 请求超时时间 (毫秒)
VITE_API_TIMEOUT=30000`;
}

// 在开发模式下自动运行配置检查
if (import.meta.env.MODE === 'development') {
  const result = checkConfig();
  if (!result.isValid || result.warnings.length > 0 || result.suggestions.length > 0) {
    printConfigCheckResult(result);
  }
} 