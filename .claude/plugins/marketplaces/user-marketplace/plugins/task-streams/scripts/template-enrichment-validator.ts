/**
 * Template Enrichment Validator
 *
 * Validates that templates include all 10 universal enrichments from SHARED_ENRICHMENTS.md
 * See: .claude-plugins/task-streams/templates/TEMPLATE-ENRICHMENT-MAPPING.md for mapping details
 */

export interface EnrichmentDefinition {
  id: number;
  name: string;
  requiredFields: string[];
  requiredHeadings: string[];
}

export const REQUIRED_ENRICHMENTS: readonly EnrichmentDefinition[] = [
  {
    id: 1,
    name: "File Locations",
    requiredFields: ["**Location:**"],
    requiredHeadings: [],
  },
  {
    id: 2,
    name: "Effort Estimation",
    requiredFields: ["**Estimated Effort:**"],
    requiredHeadings: [],
  },
  {
    id: 3,
    name: "Complexity Classification",
    requiredFields: ["**Complexity:**"],
    requiredHeadings: [],
  },
  {
    id: 4,
    name: "Acceptance Criteria",
    requiredFields: ["**Acceptance Criteria:**"],
    requiredHeadings: ["## Acceptance Criteria"],
  },
  {
    id: 5,
    name: "Regression Risk (5 Dimensions)",
    requiredFields: [
      "**Regression Risk Details:**",
      "**Impact:**",
      "**Blast Radius:**",
      "**Dependencies:**",
      "**Testing Gaps:**",
      "**Rollback Risk:**",
    ],
    requiredHeadings: ["## Regression Risk Analysis"],
  },
  {
    id: 6,
    name: "Implementation Steps",
    requiredFields: ["**Implementation Steps:**"],
    requiredHeadings: ["## Implementation Plan"],
  },
  {
    id: 7,
    name: "Code Examples",
    requiredFields: [],
    requiredHeadings: ["## Code Examples"],
  },
  {
    id: 8,
    name: "File Change Scope (3 Categories)",
    requiredFields: ["**Files to Create:**", "**Files to Modify:**", "**Files to Delete:**"],
    requiredHeadings: ["## File Changes"],
  },
  {
    id: 9,
    name: "Testing Table",
    requiredFields: ["**Required Testing:**"],
    requiredHeadings: ["## Testing Requirements"],
  },
  {
    id: 10,
    name: "Dependencies and Blocking",
    requiredFields: ["**Blocking Dependencies:**", "**Blocks:**", "**Prerequisites:**"],
    requiredHeadings: ["## Dependencies"],
  },
] as const;

export interface ValidationResult {
  passed: boolean;
  missing: string[];
}

export function validateTemplateHasAllEnrichments(templateContent: string): ValidationResult {
  const missing: string[] = [];

  for (const enrichment of REQUIRED_ENRICHMENTS) {
    // Check headings
    for (const heading of enrichment.requiredHeadings) {
      if (!templateContent.includes(heading)) {
        missing.push(
          `Enrichment #${enrichment.id} (${enrichment.name}): Missing heading "${heading}"`
        );
      }
    }

    // Check fields
    for (const field of enrichment.requiredFields) {
      if (!templateContent.includes(field)) {
        missing.push(`Enrichment #${enrichment.id} (${enrichment.name}): Missing field "${field}"`);
      }
    }
  }

  return {
    passed: missing.length === 0,
    missing,
  };
}
