import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { CLAUDE_DIR, SKILLS_DIR, HOOKS_DIR, PKG_SKILLS_DIR, PKG_HOOKS_DIR } from '../utils/config';
import { loadSkills } from '../skills/loader';
import { registerHook } from '../hooks/manager';

export async function runInstall(): Promise<void> {
  console.log('openNexus v8 설치 시작...\n');

  // 1. Node 버전 확인
  const [major] = process.versions.node.split('.').map(Number);
  if (major < 18) {
    console.error('오류: Node.js 18 이상이 필요합니다. (현재: ' + process.versions.node + ')');
    process.exit(1);
  }

  // 2. ~/.claude 디렉토리 확인 및 생성
  for (const dir of [CLAUDE_DIR, SKILLS_DIR, HOOKS_DIR]) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`디렉토리 생성: ${dir}`);
    }
  }

  // 3. 스킬 복사
  if (fs.existsSync(PKG_SKILLS_DIR)) {
    await copySkills();
  } else {
    console.warn('패키지 내 skills/ 없음 — 스킬 복사 건너뜀');
  }

  // 4. 훅 복사
  if (fs.existsSync(PKG_HOOKS_DIR)) {
    copyHooks();
  } else {
    console.warn('패키지 내 hooks/ 없음 — 훅 복사 건너뜀');
  }

  // 5. settings.json 훅 등록
  registerDefaultHooks();

  console.log('\nopenNexus v8 설치 완료!');
  console.log('→ claude --resume 으로 시작하세요\n');
}

async function copySkills(): Promise<void> {
  const pkgSkills = loadSkills(PKG_SKILLS_DIR);
  if (pkgSkills.length === 0) {
    console.log('복사할 스킬 없음');
    return;
  }

  console.log(`스킬 복사 중... (${pkgSkills.length}개)`);
  for (const skill of pkgSkills) {
    const dest = path.join(SKILLS_DIR, path.basename(skill.dir));
    if (fs.existsSync(dest)) {
      const overwrite = await confirm(`  "${skill.name}" 이미 존재합니다. 덮어쓸까요? [Y/n] `);
      if (!overwrite) {
        console.log(`  → 건너뜀: ${skill.name}`);
        continue;
      }
    }
    copyDir(skill.dir, dest);
    console.log(`  ✓ ${skill.name} (${skill.version})`);
  }
}

function copyHooks(): void {
  const hookFiles = fs.readdirSync(PKG_HOOKS_DIR).filter((f) => f.endsWith('.sh'));
  if (hookFiles.length === 0) return;

  console.log(`훅 복사 중... (${hookFiles.length}개)`);
  for (const file of hookFiles) {
    const src = path.join(PKG_HOOKS_DIR, file);
    const dest = path.join(HOOKS_DIR, file);
    fs.copyFileSync(src, dest);
    fs.chmodSync(dest, 0o755);
    console.log(`  ✓ ${file}`);
  }
}

function registerDefaultHooks(): void {
  const hooksToRegister = [
    { event: 'PostToolUse' as const, matcher: 'Write|Edit', command: `bash ${HOOKS_DIR}/post-output-detect.sh` },
    { event: 'Stop' as const, matcher: '.*', command: `bash ${HOOKS_DIR}/session-start-welcome.sh` },
  ];

  let registered = 0;
  for (const { event, matcher, command } of hooksToRegister) {
    if (fs.existsSync(command.split(' ')[1] ?? '')) {
      const added = registerHook(event, matcher, command);
      if (added) registered++;
    }
  }
  if (registered > 0) console.log(`settings.json 훅 ${registered}개 등록 완료`);
}

function copyDir(src: string, dest: string): void {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

async function confirm(question: string): Promise<boolean> {
  if (!process.stdin.isTTY) return true; // 비대화형 환경은 기본 yes
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (ans) => {
      rl.close();
      resolve(ans.toLowerCase() !== 'n');
    });
  });
}
