// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import rehypeMermaid from 'rehype-mermaid';

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
            sectionBkgColor: '#F5F4F0',
            altSectionBkgColor: '#F9F8F5',
            sectionBkgColor2: '#F5F4F0',
            taskBkgColor: '#E8F4E8',
            taskTextColor: '#2D6A2D',
            taskTextLightColor: '#6B6B6B',
            taskTextOutsideColor: '#6B6B6B',
            taskTextClickableColor: '#2D6A2D',
            activeTaskBorderColor: '#8B5E00',
            activeTaskBkgColor: '#FFF7E6',
            gridColor: '#D4C9B0',
            doneTaskBkgColor: '#E8F4E8',
            doneTaskBorderColor: '#C8DCC8',
            critBorderColor: '#8B5E00',
            critBkgColor: '#FFF7E6',
            todayLineColor: '#2D2D2D',
            weekendColor: '#F5F4F0',
          },
          gantt: {
            useWidth: 720,
          },
        },
      }],
    ],
  },
  integrations: [mdx()],
});
