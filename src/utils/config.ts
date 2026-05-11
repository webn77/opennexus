import path from 'path';
import os from 'os';

const HOME = os.homedir();

export const CLAUDE_DIR = path.join(HOME, '.claude');
export const SKILLS_DIR = path.join(CLAUDE_DIR, 'skills');
export const HOOKS_DIR = path.join(CLAUDE_DIR, 'hooks');
export const SETTINGS_FILE = path.join(CLAUDE_DIR, 'settings.json');

// dist/src/utils/ → ../../.. = 프로젝트 루트
export const PKG_SKILLS_DIR = path.join(__dirname, '..', '..', '..', 'skills');
export const PKG_HOOKS_DIR = path.join(__dirname, '..', '..', '..', 'hooks');

export function resolveHome(p: string): string {
  return p.startsWith('~') ? path.join(HOME, p.slice(1)) : p;
}
