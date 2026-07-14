// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import rehypeMermaid from 'rehype-mermaid';
import { remarkMermaidFence } from './src/lib/remark-mermaid-fence.ts';
import { rehypeMermaidTheme } from './src/lib/rehype-mermaid-theme.ts';

/**
 * Wrap every Markdown <table> in a horizontally-scrollable container so wide
 * tables don't overflow on mobile and corners can be cleanly rounded.
 * Dependency-free rehype plugin — no node_modules needed.
 */
function rehypeWrapTables() {
  return (tree) => {
    const visit = (node) => {
      if (!node || !Array.isArray(node.children)) return;
      node.children = node.children.map((child) => {
        if (child.type === 'element' && child.tagName === 'table') {
          return {
            type: 'element',
            tagName: 'div',
            properties: { className: ['table-scroll'] },
            children: [child],
          };
        }
        visit(child);
        return child;
      });
    };
    visit(tree);
  };
}

export default defineConfig({
  output: 'static',
  site: 'https://portal.coalbanks.com',  // custom domain on Cloudflare Pages
  image: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.r2.dev',
      },
      {
        protocol: 'https',
        hostname: 'pub-bb197561b1784ec2ae070297bbab0afe.r2.dev',
      },
      {
        protocol: 'https',
        hostname: 'assets.coalbanks.com',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
    ],
  },
  markdown: {
    remarkPlugins: [remarkMermaidFence],
    rehypePlugins: [
      rehypeWrapTables,
      [rehypeMermaid, {
        strategy: 'inline-svg',
        dark: false,
        mermaidConfig: {
          theme: 'base',
          themeVariables: {
            fontFamily: 'Inter, system-ui, sans-serif',
            fontSize: '13px',
            primaryColor: '#F5F4F0',
            primaryTextColor: '#1A1A1A',
            primaryBorderColor: '#D4C9B0',
            lineColor: '#6B6B6B',
            secondaryColor: '#F9F8F5',
            tertiaryColor: '#FFFFFF',
            background: '#F9F8F5',
            mainBkg: '#E8F4E8',
            secondBkg: '#FFF7E6',
            // Section bands — warmer alternating tones for clear separation
            sectionBkgColor: '#F0EDE5',
            altSectionBkgColor: '#E8E4D9',
            sectionBkgColor2: '#F0EDE5',
            // Task bars — each phase gets a distinct color via task0-3
            // task0 = Pre-Production (sage green)
            // task1 = Shoot Week (warm amber)
            // task2 = Documentary (slate blue)
            // task3 = Post-Production (warm taupe)
            taskBkgColor: '#D4C9B0',
            taskTextColor: '#1A1A1A',
            taskTextLightColor: '#6B6B6B',
            taskTextOutsideColor: '#1A1A1A',
            taskTextClickableColor: '#2D6A2D',
            activeTaskBorderColor: '#5A4500',
            activeTaskBkgColor: '#FFE8B8',
            // Grid — very faint, just for reference
            gridColor: '#EFEBE3',
            // Done tasks — muted green
            doneTaskBkgColor: '#D4E8D4',
            doneTaskBorderColor: '#B8D4B8',
            // Critical
            critBorderColor: '#8B5E00',
            critBkgColor: '#FFF7E6',
            // Today line — distinct but not harsh
            todayLineColor: '#2D6A2D',
          },
          gantt: {
            useWidth: 900,
            leftPadding: 100,
            gridLineStartPadding: 10,
            fontSize: 12,
            sectionFontSize: 13,
            numberSectionStyles: 4,
          },
        },
      }],
      rehypeMermaidTheme,
    ],
  },
  integrations: [mdx()],
});
