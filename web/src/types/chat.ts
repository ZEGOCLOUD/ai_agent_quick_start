export type ChatMessage = {
  sender: 'user' | 'bot';
  messageId: string;
  seqId: number;
  content: string;
  type: string;
  round?: number;
}