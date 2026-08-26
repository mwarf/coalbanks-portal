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
// Mirrors the documented content-type order in PORTAL-CONTENT-SPEC.md
// (brief → update → deliverable → feedback), so the project overview leads.
export const typeOrder: ProjectType[] = ['brief', 'update', 'deliverable', 'feedback'];
