export interface EnvConfig {
  APP_ENV: 'development';
  ZEGO_APP_ID: number;
  ZEGO_SERVER: string;
  APP_BASE_URL: string;
  DIGITAL_HUMAN_ID: string;
  CONFIG_ID: string;
}

const envConfig: EnvConfig = {
  // 环境标识
  APP_ENV: 'development',
  // ZEGO 控制台->项目管理->项目信息->基本信息->AppID
  // ZEGOCLOUD console->Projects Management->Project Configuration->Basic Information->AppID
  ZEGO_APP_ID: 0,
  // ZEGO 控制台->项目管理->项目信息->配置信息->Server 地址
  // ZEGOCLOUD console->Projects Management->Project Configuration->Basic Configurations->Server URL
  ZEGO_SERVER: '',
  // 部署测试业务后台后可获取。https://github.com/ZEGOCLOUD/ai_agent_quick_start_server
  // It will be available after deploying the test business backend.https://github.com/ZEGOCLOUD/ai_agent_quick_start_server
  APP_BASE_URL: '',
  // 数字人体验形象ID
  DIGITAL_HUMAN_ID: 'c4b56d5c-db98-4d91-86d4-5a97b507da97',
  CONFIG_ID: 'miniprogram'
};

export default envConfig;