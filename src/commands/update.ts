import { execSync } from 'child_process';
import { logEvent } from '../utils/logger';

export async function runUpdate(): Promise<void> {
  const pkg = require('../../../package.json') as { version: string; name: string };
  const pkgName = pkg.name;
  const current = pkg.version;

  console.log(`${pkgName} 업데이트 확인 중...\n`);

  let latest: string;
  try {
    latest = execSync(`npm view ${pkgName} version`, { timeout: 10000 }).toString().trim();
  } catch {
    console.error('오류: npm registry 조회 실패. 네트워크 연결을 확인하세요.');
    process.exit(1);
  }

  if (!latest) {
    console.error('오류: 최신 버전 정보를 가져올 수 없습니다.');
    process.exit(1);
  }

  if (current === latest) {
    console.log(`이미 최신 버전입니다 (v${current})`);
    return;
  }

  console.log(`v${current} → v${latest} 업데이트 중...`);
  try {
    execSync(`npm install -g ${pkgName}@latest`, { stdio: 'inherit', timeout: 60000 });
    logEvent('opennexus.update', { from: current, to: latest });
    console.log(`\n업데이트 완료! v${latest}`);
    console.log('변경사항을 적용하려면 npx opennexus install 을 다시 실행하세요.');
  } catch {
    console.error('업데이트 실패. 수동으로 npm install -g opennexus@latest 를 실행하세요.');
    process.exit(1);
  }
}
