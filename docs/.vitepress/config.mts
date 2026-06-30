import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "ObsidianQuickLaunch",
  description: "Open or create Obsidian vaults from the Windows right-click context menu",
  base: '/ObsidianQuickLaunch/',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'GitHub', link: 'https://github.com/ScottKirvan/ObsidianQuickLaunch' }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ScottKirvan/ObsidianQuickLaunch' },
      { icon: 'discord', link: 'https://discord.gg/TN6XJSNK5Y' }
    ]
  }
})
