import { defineConfig } from 'vitepress'
import fs from 'node:fs'
import path from 'node:path'

const root = path.resolve(__dirname, '../..')

const libs: { name: string; title: string }[] = [
  { name: 'assert', title: 'Tests Assertions' },
  { name: 'bash_utils', title: 'Bash Utilities' },
  { name: 'cli', title: 'CLI' },
  { name: 'docstring_helper', title: 'Docstring Helpers' },
  { name: 'log', title: 'Logging' },
  { name: 'parse_args', title: 'Arguments Parsing' },
  { name: 'term_utils', title: 'Terminal Utilities' },
  { name: 'user_msg', title: 'User Messages' },
]

const exists = (p: string) => fs.existsSync(path.join(root, p))

const sidebar = libs
  .filter(({ name }) => exists(`libs/${name}.md`))
  .map(({ name, title }) => ({ text: title, link: `/libraries/${name}` }))

// Docs are sourced from files outside docs/: map them to their published path.
const rewrites: Record<string, string> = {
  'README.md': 'index.md',
  'docs/libraries.md': 'libraries.md',
}
for (const { name } of libs) {
  rewrites[`libs/${name}.md`] = `libraries/${name}.md`
}

export default defineConfig({
  title: 'Bach',
  description: 'Bash utilities framework',
  base: process.env.DOCS_BASE ?? '/bach/',
  srcDir: '..',
  srcExclude: [
    '**/node_modules/**',
    'TODO.md',
    'bash_notes.md',
    'libs/TODO.md',
    'demo/**',
    'docs/README.md',
  ],
  rewrites,
  cleanUrls: true,
  ignoreDeadLinks: true,
  themeConfig: {
    nav: [
      { text: 'Bach', link: '/' },
      { text: 'Libraries', link: '/libraries', activeMatch: '/libraries' },
    ],
    sidebar: { '/libraries': [{ text: 'Libraries', link: '/libraries', items: sidebar }] },
    socialLinks: [{ icon: 'github', link: 'https://github.com/cimourdain/bach' }],
    search: { provider: 'local' },
    outline: { level: [2, 3] },
  },
})
