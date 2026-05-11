import fs from 'fs';
import path from 'path';
import os from 'os';

const EVENTS_FILE = path.join(os.homedir(), 'context', 'events.jsonl');

export interface LogEvent {
  ts: string;
  type: string;
  domain?: string;
  payload?: Record<string, unknown>;
}

export function logEvent(type: string, payload?: Record<string, unknown>): void {
  try {
    const event: LogEvent = {
      ts: new Date().toISOString(),
      type,
      domain: 'nexus',
      ...(payload && { payload }),
    };
    const line = JSON.stringify(event) + '\n';
    fs.appendFileSync(EVENTS_FILE, line, 'utf8');
  } catch {
    // 로그 실패는 조용히 무시 (주 흐름 방해 금지)
  }
}
