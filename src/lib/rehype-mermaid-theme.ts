/**
 * rehype-mermaid-theme.ts
 * 
 * Post-processes rehype-mermaid SVG output to apply custom Prairie Cinematic
 * styling that Mermaid's themeVariables don't fully cover.
 * 
 * Specifically: recolors task bars by section, improves text contrast,
 * and softens grid lines.
 */
import { visit } from 'unist-util-visit';

export function rehypeMermaidTheme() {
  return (tree) => {
    visit(tree, 'element', (node) => {
      if (node.tagName === 'svg' && node.properties?.id?.startsWith('mermaid-')) {
        // Inject a <style> override at the start of the SVG
        const styleOverride = {
          type: 'element',
          tagName: 'style',
          properties: {},
          children: [{
            type: 'text',
            value: `
              /* Grid — minimal */
              .grid .tick { stroke: #E5E0D8 !important; opacity: 0.5 !important; }
              .grid .tick text { fill: #8B8B8B !important; font-size: 10px !important; }
              
              /* Section bands — warm alternating */
              .section0 { fill: #F0EDE5 !important; opacity: 1 !important; }
              .section1, .section3 { fill: #E8E4D9 !important; opacity: 0.5 !important; }
              .section2 { fill: #F0EDE5 !important; opacity: 1 !important; }
              .sectionTitle { fill: #4A4A4A !important; font-weight: 600 !important; }
              
              /* Task bars — distinct colors per section index */
              /* task0 = Pre-Production (done = muted sage) */
              .task0 { fill: #C8DCC8 !important; stroke: #A8C8A8 !important; }
              .done0 { fill: #C8DCC8 !important; stroke: #A8C8A8 !important; }
              .taskText0 { fill: #2D4A2D !important; font-weight: 500 !important; }
              .doneText0 { fill: #4A6B4A !important; }
              
              /* task1 = Shoot Week (active = warm amber) */
              .task1 { fill: #F0C868 !important; stroke: #B8860B !important; }
              .active1 { fill: #FFB940 !important; stroke: #8B5E00 !important; }
              .done1 { fill: #D8B870 !important; stroke: #A8884A !important; }
              .taskText1 { fill: #5A3E00 !important; font-weight: 500 !important; }
              .activeText1 { fill: #4A3000 !important; font-weight: 600 !important; }
              .doneText1 { fill: #6B5A2E !important; }
              
              /* task2 = Documentary (steel blue) */
              .task2 { fill: #4A7AA8 !important; stroke: #2D5580 !important; }
              .taskText2 { fill: #FFFFFF !important; font-weight: 600 !important; }
              
              /* task3 = Post-Production (warm bronze) */
              .task3 { fill: #C4B08C !important; stroke: #9A8060 !important; }
              .taskText3 { fill: #2D1E0A !important; font-weight: 500 !important; }
              
              /* Outside labels — darker for readability */
              .taskTextOutside0, .taskTextOutside1, .taskTextOutside2, .taskTextOutside3 {
                fill: #3A3A3A !important;
              }
              
              /* Today line — sage green, dashed */
              .today { stroke: #2D6A2D !important; stroke-width: 1.5px !important; stroke-dasharray: 4,3 !important; opacity: 0.7 !important; }
              
              /* Title */
              .titleText { fill: #2D2D2D !important; font-weight: 600 !important; font-size: 15px !important; }
            `,
          }],
        };
        
        // Find the existing <style> element and prepend our overrides after it
        if (node.children) {
          const styleIdx = node.children.findIndex(
            (c) => c.type === 'element' && c.tagName === 'style'
          );
          if (styleIdx >= 0) {
            node.children.splice(styleIdx + 1, 0, styleOverride);
          } else {
            node.children.unshift(styleOverride);
          }
        }
      }
    });
  };
}
