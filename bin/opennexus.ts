#!/usr/bin/env node
import { Command } from 'commander';
import { runInstall } from '../src/commands/install';
import { runUpdate } from '../src/commands/update';
import { runStatus } from '../src/commands/status';

const pkg = require('../../package.json') as { version: string; description: string };

const program = new Command();

program
  .name('opennexus')
  .description(pkg.description)
  .version(pkg.version);

program
  .command('install')
  .description('스킬·훅·settings.json 자동 설치')
  .action(async () => {
    await runInstall();
  });

program
  .command('update')
  .description('최신 버전으로 업데이트')
  .action(async () => {
    await runUpdate();
  });

program
  .command('status')
  .description('설치 상태·버전 확인')
  .action(async () => {
    await runStatus();
  });

program.parse(process.argv);
