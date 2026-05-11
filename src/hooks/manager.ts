import fs from 'fs';
import path from 'path';
import { SETTINGS_FILE } from '../utils/config';

type HookEntry = {
  matcher: string;
  hooks: Array<{ type: string; command: string }>;
};

type Settings = {
  hooks?: {
    PreToolUse?: HookEntry[];
    PostToolUse?: HookEntry[];
    Notification?: HookEntry[];
    Stop?: HookEntry[];
    PreCompact?: HookEntry[];
  };
  [key: string]: unknown;
};

export function readSettings(): Settings {
  if (!fs.existsSync(SETTINGS_FILE)) return {};
  try {
    return JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf8'));
  } catch {
    // 파싱 실패 시 백업 후 빈 객체 반환
    const backup = SETTINGS_FILE + '.bak.' + Date.now();
    fs.copyFileSync(SETTINGS_FILE, backup);
    console.warn(`settings.json 파싱 실패 → 백업: ${backup}`);
    return {};
  }
}

export function writeSettings(settings: Settings): void {
  const dir = path.dirname(SETTINGS_FILE);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + '\n');
}

export function registerHook(
  event: keyof NonNullable<Settings['hooks']>,
  matcher: string,
  command: string,
): boolean {
  const settings = readSettings();
  if (!settings.hooks) settings.hooks = {};
  if (!settings.hooks[event]) settings.hooks[event] = [];

  const bucket = settings.hooks[event]!;
  let group = bucket.find((g) => g.matcher === matcher);
  if (!group) {
    group = { matcher, hooks: [] };
    bucket.push(group);
  }

  const exists = group.hooks.some((h) => h.command === command);
  if (exists) return false; // 중복 — 등록 생략

  group.hooks.push({ type: 'command', command });
  writeSettings(settings);
  return true;
}

export function removeHook(
  event: keyof NonNullable<Settings['hooks']>,
  command: string,
): boolean {
  const settings = readSettings();
  const bucket = settings.hooks?.[event];
  if (!bucket) return false;

  let removed = false;
  for (const group of bucket) {
    const before = group.hooks.length;
    group.hooks = group.hooks.filter((h) => h.command !== command);
    if (group.hooks.length < before) removed = true;
  }

  // 빈 그룹 제거
  settings.hooks![event] = bucket.filter((g) => g.hooks.length > 0);

  if (removed) writeSettings(settings);
  return removed;
}
