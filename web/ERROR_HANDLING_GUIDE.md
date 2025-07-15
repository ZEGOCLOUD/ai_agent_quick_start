# 错误处理系统优化指南

## 📋 优化概览

本项目已实施了全面的错误处理系统优化，解决了原有的错误处理不统一、调试信息混乱等问题。

## 🎯 主要改进

### 1. 统一错误处理系统

#### 错误分类
- **网络错误** (`NETWORK_ERROR`): 网络连接、超时等问题
- **API错误** (`API_ERROR`): 业务接口调用失败
- **SDK错误** (`SDK_INIT_ERROR`, `SDK_LOGIN_ERROR`, `SDK_STREAM_ERROR`): ZEGO SDK 相关错误
- **权限错误** (`PERMISSION_ERROR`, `AUTHENTICATION_ERROR`): 权限和认证问题
- **业务错误** (`VALIDATION_ERROR`, `BUSINESS_ERROR`): 业务逻辑和验证错误
- **配置错误** (`CONFIG_ERROR`): 配置相关问题

#### 错误严重程度
- **轻微** (`LOW`): 不影响主要功能
- **中等** (`MEDIUM`): 影响部分功能  
- **严重** (`HIGH`): 影响主要功能
- **致命** (`CRITICAL`): 应用无法继续运行

### 2. 智能错误处理

#### 自动错误恢复
```typescript
// 自动重试机制
const result = await ErrorHandler.withRetry(
  () => apiCall(),
  'API调用上下文',
  3 // 最大重试次数
);
```

#### 用户友好提示
- 根据错误严重程度显示不同类型的通知
- 提供具体的解决建议
- 支持重试和恢复操作

### 3. 结构化日志系统

#### 日志级别管理
```typescript
logger.debug('模块', '调试信息', { 数据 });
logger.info('模块', '常规信息', { 数据 });
logger.warn('模块', '警告信息', { 数据 });
logger.error('模块', '错误信息', { 错误对象, 数据 });
```

#### 专用日志方法
```typescript
logger.apiCall('GET', '/api/users', params, response);
logger.webrtc('事件名称', { 相关数据 });
logger.userAction('用户操作', { 操作数据 });
```

### 4. 错误边界组件

#### 全局错误捕获
- 自动捕获组件错误和未处理的 Promise 拒绝
- 提供用户友好的错误页面
- 支持错误重试和应用重置

#### 开发调试支持
- 开发模式下显示详细错误信息
- 错误堆栈追踪
- 自动错误上报（可配置）

## 🔧 使用指南

### 基本错误处理

#### 在组件中使用
```typescript
import { ErrorHandler, createError } from '@/utils/error-handler';

// 处理异步操作错误
try {
  const result = await someAsyncOperation();
} catch (error) {
  ErrorHandler.handle(error, 'ComponentName.methodName');
}

// 创建特定类型的错误
throw createError.network('网络连接失败', { canRetry: true });
throw createError.permission('权限不足');
```

#### 在服务层使用
```typescript
// 带重试的API调用
const data = await ErrorHandler.withRetry(
  () => httpClient.get('/api/data'),
  '获取数据',
  3
);
```

### 日志记录最佳实践

#### 结构化日志
```typescript
// ✅ 推荐：结构化日志
logger.info('USER', '用户登录成功', { 
  userId, 
  roomId, 
  timestamp: Date.now() 
});

// ❌ 避免：字符串拼接
console.log(`用户 ${userId} 登录房间 ${roomId} 成功`);
```

#### 敏感信息保护
```typescript
// ✅ 推荐：隐藏敏感信息
logger.info('AUTH', 'Token 获取成功', { 
  userId,
  tokenLength: token.length,
  expiresIn: expires 
});

// ❌ 避免：暴露敏感信息
logger.info('AUTH', 'Token 获取成功', { 
  userId,
  token: token // 不要记录实际 token
});
```

### 错误恢复策略

#### 网络错误处理
```typescript
// 自动重试网络请求
const result = await ErrorHandler.withRetry(
  () => apiCall(),
  '网络请求',
  3 // 重试3次
);
```

#### 用户操作错误
```typescript
// 显示错误但不阻断用户操作
try {
  await saveUserData();
} catch (error) {
  // 显示错误提示，但允许用户继续操作
  ErrorHandler.handle(error, 'saveUserData');
}
```

## 📊 错误监控和分析

### 错误统计
- 所有错误都会被记录到结构化日志中
- 支持错误类型和严重程度统计
- 可集成第三方监控服务（如 Sentry）

### 性能监控
```typescript
// API 调用性能监控
logger.apiCall('POST', '/api/login', requestData, {
  status: response.status,
  duration: responseTime,
  size: responseSize
});
```

## 🔄 迁移指南

### 从旧错误处理迁移

#### 替换 console.log
```typescript
// 旧方式
console.log("mytag 用户登录成功", userId);

// 新方式
logger.info('USER', '用户登录成功', { userId });
```

#### 替换 ElMessage.error
```typescript
// 旧方式
try {
  await operation();
} catch (error) {
  console.error('操作失败', error);
  ElMessage.error(error.message || '操作失败');
}

// 新方式
try {
  await operation();
} catch (error) {
  ErrorHandler.handle(error, 'operation');
}
```

### 错误处理装饰器
```typescript
class SomeService {
  @handleAsyncErrors
  async someMethod() {
    // 方法中的错误会自动被处理
    throw new Error('测试错误');
  }
}
```

## ⚙️ 配置选项

### 错误处理器配置
```typescript
// 更新错误处理配置
ErrorHandler.updateConfig({
  showNotification: true,    // 是否显示用户通知
  logError: true,           // 是否记录错误日志
  reportError: false,       // 是否上报错误
  enableRetry: true,        // 是否启用重试
  maxRetries: 3,           // 最大重试次数
  retryDelay: 1000,        // 重试延迟（毫秒）
});
```

### 日志级别配置
通过环境变量 `VITE_LOG_LEVEL` 控制日志输出级别：
- `debug`: 输出所有级别日志
- `info`: 输出 info、warn、error 级别日志
- `warn`: 输出 warn、error 级别日志
- `error`: 仅输出 error 级别日志

## 🧪 测试建议

### 错误处理测试
```typescript
// 测试错误处理逻辑
it('应该正确处理网络错误', async () => {
  const networkError = new Error('Network Error');
  const handledError = ErrorHandler.handle(networkError, 'test');
  
  expect(handledError.type).toBe(ErrorType.NETWORK_ERROR);
  expect(handledError.canRetry).toBe(true);
});
```

### 集成测试
```typescript
// 测试错误恢复机制
it('应该在网络错误后自动重试', async () => {
  let attempts = 0;
  const operation = jest.fn().mockImplementation(() => {
    attempts++;
    if (attempts < 3) {
      throw new Error('Network Error');
    }
    return 'success';
  });

  const result = await ErrorHandler.withRetry(operation, 'test', 3);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

## 📈 最佳实践总结

1. **错误分类明确**：使用正确的错误类型和严重程度
2. **日志结构化**：使用结构化数据而非字符串拼接
3. **用户体验优先**：提供友好的错误提示和恢复选项
4. **开发调试友好**：开发模式下提供详细错误信息
5. **性能考虑**：避免在生产环境输出过多调试信息
6. **安全意识**：不在日志中暴露敏感信息
7. **监控集成**：为生产环境准备错误监控和上报

## 🔮 未来扩展

- 集成 Sentry 等错误监控服务
- 添加性能监控功能
- 实现错误预测和预防机制
- 添加用户行为分析
- 支持离线错误缓存和同步

---

通过这套完整的错误处理系统，项目的稳定性、可维护性和用户体验都得到了显著提升。 