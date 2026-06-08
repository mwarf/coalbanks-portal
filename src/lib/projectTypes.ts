// Shared metadata for the content collection `type` field.
// Keeps labels consistent across TypeBadge, ProjectSummary, and any future UI.

export type ProjectType = 'update' | 'deliverable' | 'feedback' | 'brief';

export const typeLabel: Record<ProjectType, string> = {
  update: 'Update',
  deliverable: 'Deliverable',
  feedback: 'Feedback',
  brief: 'Brief',
};

export const typeLabelPlural: Record<ProjectType, string> = {
  update: 'Updates',
  deliverable: 'Deliverables',
  feedback: 'Feedback',
  brief: 'Briefs',
};

// Order used when grouping / listing types in summaries.
export const typeOrder: ProjectType[] = ['deliverable', 'update', 'feedback', 'brief'];
