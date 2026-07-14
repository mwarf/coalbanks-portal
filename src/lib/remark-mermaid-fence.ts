/**
 * remark-mermaid-fence.ts
 * 
 * Converts fenced ```mermaid code blocks into <pre class="mermaid"> elements
 * before Shiki/rehype processing, so rehype-mermaid can pick them up.
 * 
 * This bypasses syntax highlighting for mermaid blocks specifically.
 */
import { visit } from 'unist-util-visit';

export function remarkMermaidFence() {
  return (tree) => {
    visit(tree, 'code', (node, index, parent) => {
      if (node.lang === 'mermaid' && parent) {
        // Replace the code node with an HTML node that rehype-mermaid will recognize
        parent.children[index] = {
          type: 'html',
          value: `<pre class="mermaid">${node.value}</pre>`,
        };
      }
    });
  };
}
