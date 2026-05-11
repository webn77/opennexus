#!/usr/bin/env node
import { Command } from 'commander';
import { runInstall } from '../src/commands/install';

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

program.parse(process.argv);
