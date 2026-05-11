import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { CLAUDE_DIR, SKILLS_DIR, HOOKS_DIR, SETTINGS_FILE } from '../utils/config';
import { loadSkills } from '../skills/loader';
import { readSettings } from '../hooks/manager';

export async function runStatus(): Promise<void> {
  const pkg = require('../../../package.json') as { version: string; name: string };
  console.log(`${pkg.name} v${pkg.version}\n`);

  // 1. 설치 경로
  console.log('설치 경로:');
  check('  ~/.claude/', CLAUDE_DIR);
  check('  ~/.claude/skills/', SKILLS_DIR);
  check('  ~/.claude/hooks/', HOOKS_DIR);
  check('  settings.json', SETTINGS_FILE);

  // 2. 스킬 목록
  const skills = loadSkills(SKILLS_DIR);
  console.log(`\n스킬 (${skills.length}개):`);
  for (const s of skills) {
    console.log(`  ✓ ${s.name} ${s.version}`);
  }
  if (skills.length === 0) console.log('  (없음 — npx opennexus install 실행 필요)');

  // 3. 훅 등록 현황
  const settings = readSettings();
  const hookEvents = settings.hooks ?? {};
  const totalHooks = Object.values(hookEvents).reduce(
    (sum, bucket) => sum + bucket.reduce((s, g) => s + g.hooks.length, 0),
    0,
  );
  console.log(`\n훅 (${totalHooks}개 등록):`);
  for (const [event, bucket] of Object.entries(hookEvents)) {
    for (const group of bucket) {
      for (const hook of group.hooks) {
        console.log(`  [${event}] ${hook.command.slice(0, 60)}`);
      }
    }
  }

  // 4. npm 최신 버전
  try {
    const latest = execSync(`npm view ${pkg.name} version 2>/dev/null`, { timeout: 5000 }).toString().trim();
    if (latest && latest !== pkg.version) {
      console.log(`\n업데이트 가능: v${pkg.version} → v${latest}`);
      console.log('  npx opennexus update 로 업데이트하세요');
    } else if (latest) {
      console.log(`\n최신 버전 사용 중 (v${pkg.version})`);
    }
  } catch {
    // npm registry 조회 실패는 조용히 무시
  }
}

function check(label: string, filePath: string): void {
  const exists = fs.existsSync(filePath);
  console.log(`${exists ? '✓' : '✗'} ${label}`);
}
