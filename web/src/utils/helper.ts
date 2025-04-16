import CryptoJS, { MD5 } from 'crypto-js';
import config from "../keycenter";
import { SIGNATURE_VERSION } from "../constant";

// 生成逻辑建议放在业务后台
export function generateToken(
  userID: string,
  appID: number,
  serverSecret: string,
  seconds: number = 7200
) {
  if (!userID) return "";
  // 构造 加密数据
  const time = (Date.now() / 1000) | 0;
  const body = {
    app_id: appID,
    user_id: userID,
    nonce: (Math.random() * 2147483647) | 0,
    ctime: time,
    expire: time + (seconds || 7200), // 有效时长不能超过 24 天
  };
  // 加密 body
  const key = CryptoJS.enc.Utf8.parse(serverSecret);
  let iv = Math.random().toString().substring(2, 18);
  if (iv.length < 16) iv += iv.substring(0, 16 - iv.length);

  const ciphertext = CryptoJS.AES.encrypt(JSON.stringify(body), key, {
    iv: CryptoJS.enc.Utf8.parse(iv),
  }).toString();
  const ciphert = new Uint8Array(
    Array.from(atob(ciphertext)).map((val) => val.charCodeAt(0))
  );
  const len_ciphert = ciphert.length;

  // 组装 token 数据
  const uint8 = new Uint8Array(8 + 2 + 16 + 2 + len_ciphert);
  // expire: 8
  uint8.set([0, 0, 0, 0]);
  uint8.set(new Uint8Array(new Int32Array([body.expire]).buffer).reverse(), 4);
  // iv length: 2
  uint8[8] = iv.length >> 8;
  uint8[9] = iv.length - (uint8[8] << 8);
  // iv: 16
  uint8.set(new Uint8Array(Array.from(iv).map((val) => val.charCodeAt(0))), 10);
  // 密文 length: 2
  uint8[26] = len_ciphert >> 8;
  uint8[27] = len_ciphert - (uint8[26] << 8);
  // 密文
  uint8.set(ciphert, 28);

  const token = `04${btoa(String.fromCharCode(...Array.from(uint8)))}`;

  return token;
}

// 生成逻辑建议放在业务后台
export function generatePaasSignature(
  appId: number,
  serverSecret: string
) {
  const timeStamp = Math.round(Date.now() / 1000);
  const signatureNonce = String(timeStamp);
  const str = appId + signatureNonce + serverSecret + timeStamp;
  const signature = MD5(str).toString(); // 规定使用哈希算法中的MD5算法
  return {
    Signature: signature,
    SignatureNonce: signatureNonce,
    Timestamp: timeStamp
  };
}

export const generateParams = (cmd: string): string => {
  const { appId, serverSecret } = config;
  const { Signature, SignatureNonce, Timestamp } = generatePaasSignature(appId, serverSecret);
  return `/?Action=${cmd}&AppId=${appId}&SignatureNonce=${SignatureNonce}&Timestamp=${Timestamp}&Signature=${Signature}&SignatureVersion=${SIGNATURE_VERSION}`;
};
