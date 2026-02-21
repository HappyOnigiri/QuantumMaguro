import { defineConfig, Plugin } from 'vite';
import { resolve } from 'path';
import fs from 'fs';

function getAppDirectories(rootDir: string) {
  return fs.readdirSync(rootDir, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory() && !dirent.name.startsWith('.') && !dirent.name.startsWith('_') && dirent.name !== 'node_modules')
    .map(dirent => dirent.name);
}

function getRollupInputs(rootDir: string) {
  const dirs = getAppDirectories(rootDir);
  const inputs: Record<string, string> = {
    main: resolve(rootDir, 'index.html')
  };
  for (const dir of dirs) {
    const indexPath = resolve(rootDir, dir, 'index.html');
    const readmePath = resolve(rootDir, dir, 'README.md');
    if (fs.existsSync(indexPath) && fs.existsSync(readmePath)) {
      inputs[dir] = indexPath;
    }
  }
  return inputs;
}

function generatePortalCardsPlugin(): Plugin {
  return {
    name: 'generate-portal-cards',
    transformIndexHtml(html: string) {
      if (!html.includes('<!-- PORTAL_CARDS -->')) return html;

      const rootDir = __dirname;
      const dirs = getAppDirectories(rootDir);

      const cards: string[] = [];

      for (const dir of dirs) {
        const indexPath = resolve(rootDir, dir, 'index.html');
        const readmePath = resolve(rootDir, dir, 'README.md');

        // アプリであることを判定 (index.html と README.md の両方が存在)
        if (fs.existsSync(indexPath) && fs.existsSync(readmePath)) {
          const readmeContent = fs.readFileSync(readmePath, 'utf8');
          const lines = readmeContent.split(/\r?\n/);

          let title = dir;
          let description = '';

          // タイトル抽出 (# から始まる行)
          const titleLine = lines.find(line => line.startsWith('# '));
          if (titleLine) {
            title = titleLine.replace(/^#\s*/, '').trim();
          }

          // 説明文抽出 (タイトル行などの見出しや空白行を除き、最初にヒットしたテキスト行)
          const descLine = lines.find(line => line.trim() !== '' && !line.startsWith('#'));
          if (descLine) {
            description = descLine.trim();
          }

          // カードHTMLの生成
          const cardHtml = `
    <a href="./${dir}/" class="card">
      <h2>${title}</h2>
      <p>${description}</p>
    </a>`;
          cards.push(cardHtml);
        }
      }

      return html.replace('<!-- PORTAL_CARDS -->', cards.join('\n'));
    }
  };
}

export default defineConfig({
  plugins: [generatePortalCardsPlugin()],
  server: {
    port: 5181,
  },
  build: {
    rollupOptions: {
      input: getRollupInputs(__dirname)
    }
  }
});
