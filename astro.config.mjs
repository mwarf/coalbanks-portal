// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';

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
    rehypePlugins: [rehypeWrapTables],
  },
  integrations: [mdx()],
});
