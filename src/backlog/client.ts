import fs from 'fs';
import path from 'path';
import os from 'os';
import https from 'https';

const LINEAR_API = 'https://api.linear.app/graphql';
const BACKLOG_JSON = path.join(os.homedir(), 'context', 'backlog.json');
const API_KEY_FILE = path.join(os.homedir(), '.linear_api_key');

function getLinearKey(): string | null {
  if (process.env.LINEAR_API_KEY) return process.env.LINEAR_API_KEY;
  if (fs.existsSync(API_KEY_FILE)) return fs.readFileSync(API_KEY_FILE, 'utf8').trim();
  return null;
}

function gql(query: string, variables: Record<string, unknown> = {}): Promise<unknown> {
  const key = getLinearKey();
  if (!key) throw new Error('LINEAR_API_KEY 없음 — ~/.linear_api_key 파일 또는 환경변수 설정 필요');

  const body = JSON.stringify({ query, variables });
  return new Promise((resolve, reject) => {
    const req = https.request(LINEAR_API, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: key,
      },
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(data) as { data?: unknown; errors?: unknown[] };
          if (json.errors) reject(new Error(JSON.stringify(json.errors)));
          else resolve(json.data);
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(30000, () => { req.destroy(); reject(new Error('Linear API timeout')); });
    req.write(body);
    req.end();
  });
}

export interface BacklogItem {
  id: string;
  title: string;
  status: string;
  domain: string;
  rice_score: number;
}

export async function getActiveItems(): Promise<BacklogItem[]> {
  const backend = process.env.BACKLOG_BACKEND ?? 'linear';

  if (backend === 'json') return getJsonItems();

  try {
    return await getLinearItems();
  } catch {
    // Linear 실패 시 JSON fallback
    return getJsonItems();
  }
}

async function getLinearItems(): Promise<BacklogItem[]> {
  const data = await gql(`{
    issues(filter: { state: { name: { in: ["In Progress", "Todo"] } } }, first: 50) {
      nodes {
        identifier title
        state { name }
        labels { nodes { name } }
        priority
      }
    }
  }`) as { issues: { nodes: Array<{ identifier: string; title: string; state: { name: string }; labels: { nodes: Array<{ name: string }> }; priority: number }> } };

  return data.issues.nodes.map((n) => ({
    id: n.identifier,
    title: n.title,
    status: n.state.name === 'In Progress' ? 'in_progress' : 'sprint',
    domain: n.labels.nodes[0]?.name ?? 'work',
    rice_score: (5 - n.priority) * 20,
  }));
}

function getJsonItems(): BacklogItem[] {
  if (!fs.existsSync(BACKLOG_JSON)) return [];
  try {
    const d = JSON.parse(fs.readFileSync(BACKLOG_JSON, 'utf8')) as { items?: BacklogItem[] };
    return (d.items ?? []).filter((i) => i.status === 'sprint' || i.status === 'in_progress');
  } catch {
    return [];
  }
}
