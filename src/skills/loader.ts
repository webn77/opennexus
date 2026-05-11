import fs from 'fs';
import path from 'path';

export interface SkillMeta {
  name: string;
  version: string;
  description: string;
  dir: string;
}

export function loadSkills(skillsDir: string): SkillMeta[] {
  if (!fs.existsSync(skillsDir)) return [];

  const skills: SkillMeta[] = [];

  for (const entry of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;

    const skillMdPath = path.join(skillsDir, entry.name, 'SKILL.md');
    if (!fs.existsSync(skillMdPath)) continue;

    const meta = parseSkillMd(skillMdPath, entry.name);
    if (meta) skills.push({ ...meta, dir: path.join(skillsDir, entry.name) });
  }

  return skills;
}

function parseSkillMd(filePath: string, dirName: string): Omit<SkillMeta, 'dir'> | null {
  const content = fs.readFileSync(filePath, 'utf8');

  // frontmatter 파싱 (--- ... --- 블록)
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (fmMatch) {
    const fm = fmMatch[1];
    return {
      name: extractField(fm, 'name') ?? dirName,
      version: extractField(fm, 'version') ?? '0.1.0',
      description: extractField(fm, 'description') ?? '',
    };
  }

  // frontmatter 없으면 첫 번째 # 헤딩에서 이름 추출 (선행 / 제거)
  const headingMatch = content.match(/^#\s+(.+)/m);
  return {
    name: headingMatch?.[1]?.trim().replace(/^\//, '') ?? dirName,
    version: '0.1.0',
    description: '',
  };
}

function extractField(frontmatter: string, key: string): string | undefined {
  const match = frontmatter.match(new RegExp(`^${key}:\\s*(.+)$`, 'm'));
  return match?.[1]?.trim().replace(/^['"]|['"]$/g, '');
}
