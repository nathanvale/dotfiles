/**
 * Integration Tests for Template System (Task 3.1 - RED Phase)
 *
 * Comprehensive integration tests verifying the entire template system working together
 * Tests the complete workflow from discovery to validation
 */

import { mkdtemp, rm, writeFile, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { describe, it, expect, beforeAll, afterAll } from "vitest";

import { validateTemplateHasAllEnrichments } from "../../scripts/template-enrichment-validator.js";
import { TemplateRegistry } from "../../scripts/template-registry.js";

import type { TemplateMetadata } from "../../scripts/template-registry.js";

const TEMPLATES_DIR = join(process.cwd(), ".claude-plugins/task-streams/templates");

const EXPECTED_TEMPLATES = ["bug-findings", "generic", "security", "spec", "tech-debt"];

describe("Template System Integration Tests", () => {
  describe("End-to-End Discovery Workflow", () => {
    it("should list all templates and retrieve full content for each", async () => {
      // Phase 1: List all templates
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      expect(templates).toHaveLength(5);
      expect(Array.isArray(templates)).toBe(true);

      // Phase 2: For each template, retrieve full content
      for (const template of templates) {
        const content = await TemplateRegistry.getTemplate(template.templateName, TEMPLATES_DIR);

        expect(content.length).toBeGreaterThan(0);
        expect(content.trimStart().startsWith("---")).toBe(true);
        expect(content).toContain(`templateName: ${template.templateName}`);
      }
    });

    it("should verify content matches metadata for all templates", async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      for (const template of templates) {
        // Get metadata via getTemplateMetadata
        const metadata = await TemplateRegistry.getTemplateMetadata(
          template.templateName,
          TEMPLATES_DIR
        );

        // Get full content
        const content = await TemplateRegistry.getTemplate(template.templateName, TEMPLATES_DIR);

        // Verify metadata matches content frontmatter
        expect(content).toContain(`templateName: ${metadata.templateName}`);
        expect(content).toContain(`templateVersion: ${metadata.templateVersion}`);
        expect(content).toContain(`description: ${metadata.description}`);
        expect(content).toContain(`requiredEnrichments: ${metadata.requiredEnrichments}`);
        expect(content).toContain(`formatSkill: ${metadata.formatSkill}`);
      }
    });

    it("should verify all templates have all 10 enrichments", async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      for (const template of templates) {
        // Verify requiredEnrichments metadata is 10
        expect(template.requiredEnrichments).toBe(10);

        // Get content and validate using enrichment validator
        const content = await TemplateRegistry.getTemplate(template.templateName, TEMPLATES_DIR);

        const validation = validateTemplateHasAllEnrichments(content);

        expect(validation.passed).toBe(true);
        expect(validation.missing).toEqual([]);
      }
    });
  });

  describe("External Plugin Discovery Pattern", () => {
    it("should allow external plugin to list templates and get JSON response", async () => {
      // Simulate external plugin calling list-templates
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      // Plugin receives JSON-compatible structure
      const jsonOutput = JSON.parse(JSON.stringify(templates));

      expect(Array.isArray(jsonOutput)).toBe(true);
      expect(jsonOutput).toHaveLength(5);

      // Verify JSON structure has all required fields
      for (const template of jsonOutput) {
        expect(template).toHaveProperty("templateName");
        expect(template).toHaveProperty("templateVersion");
        expect(template).toHaveProperty("description");
        expect(template).toHaveProperty("requiredEnrichments");
        expect(template).toHaveProperty("formatSkill");
        expect(template).toHaveProperty("path");
      }
    });

    it("should allow plugin to pick a template and retrieve structure", async () => {
      // Step 1: Plugin lists templates
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      // Step 2: Plugin picks first template
      const selectedTemplate = templates[0]!;
      expect(selectedTemplate).toBeDefined();

      // Step 3: Plugin retrieves full template structure
      const content = await TemplateRegistry.getTemplate(
        selectedTemplate.templateName,
        TEMPLATES_DIR
      );

      // Step 4: Plugin validates it's a valid template
      expect(content.length).toBeGreaterThan(0);
      expect(content).toContain("---"); // Has frontmatter
      expect(content).toContain(`templateName: ${selectedTemplate.templateName}`);

      // Step 5: Plugin can parse the structure
      const lines = content.split("\n");
      expect(lines.length).toBeGreaterThan(10); // Has substantial content
    });

    it("should validate output format is consistent across all templates", async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      for (const template of templates) {
        const content = await TemplateRegistry.getTemplate(template.templateName, TEMPLATES_DIR);

        // All templates must:
        // 1. Start with frontmatter delimiter
        expect(content.trimStart().startsWith("---")).toBe(true);

        // 2. Have closing frontmatter delimiter
        const lines = content.split("\n");
        const closingDelimiterIndex = lines.findIndex(
          (line, idx) => idx > 0 && line.trim() === "---"
        );
        expect(closingDelimiterIndex).toBeGreaterThan(0);

        // 3. Have content after frontmatter
        expect(lines.length).toBeGreaterThan(closingDelimiterIndex + 1);

        // 4. Have all enrichment sections
        expect(content).toContain("## Acceptance Criteria");
        expect(content).toContain("## Implementation Plan");
        expect(content).toContain("## Testing Requirements");
      }
    });
  });

  describe("Validator Integration", () => {
    it("should retrieve template via TemplateRegistry and validate using enrichment validator", async () => {
      // Integration: TemplateRegistry -> Validator
      const content = await TemplateRegistry.getTemplate("bug-findings", TEMPLATES_DIR);

      const validation = validateTemplateHasAllEnrichments(content);

      expect(validation.passed).toBe(true);
      expect(validation.missing).toEqual([]);
    });

    it("should pass validation for all 5 templates", async () => {
      for (const templateName of EXPECTED_TEMPLATES) {
        const content = await TemplateRegistry.getTemplate(templateName, TEMPLATES_DIR);

        const validation = validateTemplateHasAllEnrichments(content);

        expect(validation.passed).toBe(true);
        expect(validation.missing).toEqual([]);
      }
    });

    it("should use TemplateRegistry.validateTemplate() convenience method", async () => {
      // Integration: All-in-one validation method
      for (const templateName of EXPECTED_TEMPLATES) {
        const isValid = await TemplateRegistry.validateTemplate(templateName, TEMPLATES_DIR);

        expect(isValid).toBe(true);
      }
    });

    it("should handle mixed valid/invalid templates gracefully", async () => {
      // Create temp directory with one valid and one invalid template
      const tempDir = await mkdtemp(join(tmpdir(), "integration-mixed-"));

      try {
        // Valid template
        await writeFile(
          join(tempDir, "valid.template.md"),
          `---
templateName: valid
templateVersion: 1.0.0
description: Valid template
requiredEnrichments: 10
formatSkill: format-valid
---

**Location:**
**Estimated Effort:**
**Complexity:**
## Acceptance Criteria
**Acceptance Criteria:**
## Regression Risk Analysis
**Regression Risk Details:**
**Impact:**
**Blast Radius:**
**Dependencies:**
**Testing Gaps:**
**Rollback Risk:**
## Implementation Plan
**Implementation Steps:**
## Code Examples
## File Changes
**Files to Create:**
**Files to Modify:**
**Files to Delete:**
## Testing Requirements
**Required Testing:**
## Dependencies
**Blocking Dependencies:**
**Blocks:**
**Prerequisites:**
`
        );

        // Invalid template (missing most enrichments)
        await writeFile(
          join(tempDir, "invalid.template.md"),
          `---
templateName: invalid
templateVersion: 1.0.0
description: Invalid template
requiredEnrichments: 10
formatSkill: format-invalid
---

# Incomplete Template
Missing all enrichments
`
        );

        // Validate each template independently
        const validResult = await TemplateRegistry.validateTemplate("valid", tempDir);
        const invalidResult = await TemplateRegistry.validateTemplate("invalid", tempDir);

        expect(validResult).toBe(true);
        expect(invalidResult).toBe(false);
      } finally {
        await rm(tempDir, { recursive: true });
      }
    });
  });

  describe("Metadata Consistency", () => {
    it("metadata from listTemplates() should match getTemplateMetadata()", async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      for (const listMetadata of templates) {
        const getMetadata = await TemplateRegistry.getTemplateMetadata(
          listMetadata.templateName,
          TEMPLATES_DIR
        );

        // All fields should match
        expect(listMetadata.templateName).toBe(getMetadata.templateName);
        expect(listMetadata.templateVersion).toBe(getMetadata.templateVersion);
        expect(listMetadata.description).toBe(getMetadata.description);
        expect(listMetadata.requiredEnrichments).toBe(getMetadata.requiredEnrichments);
        expect(listMetadata.formatSkill).toBe(getMetadata.formatSkill);
        expect(listMetadata.path).toBe(getMetadata.path);
      }
    });

    it("metadata from getTemplate() frontmatter should match getTemplateMetadata()", async () => {
      for (const templateName of EXPECTED_TEMPLATES) {
        const metadata = await TemplateRegistry.getTemplateMetadata(templateName, TEMPLATES_DIR);

        const content = await TemplateRegistry.getTemplate(templateName, TEMPLATES_DIR);

        // Verify frontmatter matches metadata
        expect(content).toContain(`templateName: ${metadata.templateName}`);
        expect(content).toContain(`templateVersion: ${metadata.templateVersion}`);
        expect(content).toContain(`description: ${metadata.description}`);
        expect(content).toContain(`requiredEnrichments: ${metadata.requiredEnrichments}`);
        expect(content).toContain(`formatSkill: ${metadata.formatSkill}`);
      }
    });

    it("path field should be consistent across all API calls", async () => {
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);

      for (const template of templates) {
        const metadata = await TemplateRegistry.getTemplateMetadata(
          template.templateName,
          TEMPLATES_DIR
        );

        // Path should be consistent
        expect(template.path).toBe(metadata.path);

        // Path should be absolute
        expect(template.path).toMatch(/^\//);
        expect(metadata.path).toMatch(/^\//);

        // Path should contain template filename
        expect(template.path).toContain(`${template.templateName}.template.md`);
        expect(metadata.path).toContain(`${template.templateName}.template.md`);
      }
    });
  });

  describe("Error Propagation", () => {
    it("error from missing template should flow through API consistently", async () => {
      const missingTemplateName = "does-not-exist";

      // All API methods should throw for missing template
      await expect(
        TemplateRegistry.getTemplate(missingTemplateName, TEMPLATES_DIR)
      ).rejects.toThrow(/Template "does-not-exist" not found/);

      await expect(
        TemplateRegistry.getTemplateMetadata(missingTemplateName, TEMPLATES_DIR)
      ).rejects.toThrow(/Template "does-not-exist" not found/);

      await expect(
        TemplateRegistry.validateTemplate(missingTemplateName, TEMPLATES_DIR)
      ).rejects.toThrow(/Template "does-not-exist" not found/);
    });

    it("error messages should be consistent across methods", async () => {
      const errors: string[] = [];

      try {
        await TemplateRegistry.getTemplate("missing", TEMPLATES_DIR);
      } catch (error) {
        errors.push((error as Error).message);
      }

      try {
        await TemplateRegistry.getTemplateMetadata("missing", TEMPLATES_DIR);
      } catch (error) {
        errors.push((error as Error).message);
      }

      try {
        await TemplateRegistry.validateTemplate("missing", TEMPLATES_DIR);
      } catch (error) {
        errors.push((error as Error).message);
      }

      // All error messages should contain template name and helpful context
      for (const errorMsg of errors) {
        expect(errorMsg).toContain('Template "missing" not found');
        expect(errorMsg).toContain("missing.template.md");
      }

      // All errors should be consistent
      expect(errors[0]).toBe(errors[1]);
      expect(errors[1]).toBe(errors[2]);
    });

    it("should not have silent failures - all errors should throw", async () => {
      let caughtError = false;

      try {
        await TemplateRegistry.getTemplate("non-existent", TEMPLATES_DIR);
      } catch (_error) {
        caughtError = true;
      }

      expect(caughtError).toBe(true);
    });
  });

  describe("Directory Operations", () => {
    let tempDir: string;

    beforeAll(async () => {
      tempDir = await mkdtemp(join(tmpdir(), "integration-dir-"));
    });

    afterAll(async () => {
      await rm(tempDir, { recursive: true });
    });

    it("should work with custom template directory", async () => {
      const customDir = join(tempDir, "custom-templates");
      await mkdir(customDir, { recursive: true });

      // Create a valid template in custom directory
      await writeFile(
        join(customDir, "custom.template.md"),
        `---
templateName: custom
templateVersion: 1.0.0
description: Custom template in custom directory
requiredEnrichments: 10
formatSkill: format-custom
---

**Location:**
**Estimated Effort:**
**Complexity:**
## Acceptance Criteria
**Acceptance Criteria:**
## Regression Risk Analysis
**Regression Risk Details:**
**Impact:**
**Blast Radius:**
**Dependencies:**
**Testing Gaps:**
**Rollback Risk:**
## Implementation Plan
**Implementation Steps:**
## Code Examples
## File Changes
**Files to Create:**
**Files to Modify:**
**Files to Delete:**
## Testing Requirements
**Required Testing:**
## Dependencies
**Blocking Dependencies:**
**Blocks:**
**Prerequisites:**
`
      );

      // Test all operations with custom directory
      const templates = await TemplateRegistry.listTemplates(customDir);
      expect(templates).toHaveLength(1);
      expect(templates[0]!.templateName).toBe("custom");

      const content = await TemplateRegistry.getTemplate("custom", customDir);
      expect(content).toContain("templateName: custom");

      const metadata = await TemplateRegistry.getTemplateMetadata("custom", customDir);
      expect(metadata.templateName).toBe("custom");

      const isValid = await TemplateRegistry.validateTemplate("custom", customDir);
      expect(isValid).toBe(true);
    });

    it("should handle empty directory gracefully", async () => {
      const emptyDir = join(tempDir, "empty");
      await mkdir(emptyDir, { recursive: true });

      const templates = await TemplateRegistry.listTemplates(emptyDir);
      expect(templates).toEqual([]);
    });
  });

  describe("Complete Workflow Simulation", () => {
    it("should simulate external plugin complete workflow", async () => {
      // Step 1: Plugin discovers available templates
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);
      expect(templates.length).toBeGreaterThan(0);

      // Step 2: Plugin filters templates by formatSkill
      const bugTemplate = templates.find((t) => t.formatSkill === "format-bug-findings");
      expect(bugTemplate).toBeDefined();

      // Step 3: Plugin retrieves full template structure
      const content = await TemplateRegistry.getTemplate(bugTemplate!.templateName, TEMPLATES_DIR);
      expect(content.length).toBeGreaterThan(0);

      // Step 4: Plugin validates template has required structure
      const validation = validateTemplateHasAllEnrichments(content);
      expect(validation.passed).toBe(true);

      // Step 5: Plugin can now use template as structure contract
      expect(content).toContain("## Acceptance Criteria");
      expect(content).toContain("## Implementation Plan");
      expect(content).toContain("## Testing Requirements");
      expect(content).toContain("## Dependencies");
    });

    it("should handle complete CRUD-like operations (no updates/deletes)", async () => {
      // CREATE is handled by filesystem (out of scope)

      // READ: List all templates
      const allTemplates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);
      expect(allTemplates).toHaveLength(5);

      // READ: Get specific template
      const specificTemplate = await TemplateRegistry.getTemplate("generic", TEMPLATES_DIR);
      expect(specificTemplate).toContain("templateName: generic");

      // READ: Get metadata only
      const metadata = await TemplateRegistry.getTemplateMetadata("generic", TEMPLATES_DIR);
      expect(metadata.templateName).toBe("generic");

      // VALIDATE: Ensure data integrity
      const isValid = await TemplateRegistry.validateTemplate("generic", TEMPLATES_DIR);
      expect(isValid).toBe(true);
    });
  });

  describe("Performance and Efficiency", () => {
    it("should efficiently list all templates without loading full content", async () => {
      // listTemplates() should only read frontmatter, not full content
      const start = Date.now();
      const templates = await TemplateRegistry.listTemplates(TEMPLATES_DIR);
      const duration = Date.now() - start;

      expect(templates).toHaveLength(5);

      // Should complete quickly (< 500ms is reasonable for 5 small files)
      expect(duration).toBeLessThan(500);
    });

    it("should cache template content efficiently when called multiple times", async () => {
      // Note: Current implementation doesn't cache, but verifies repeated calls work
      const templateName = "bug-findings";

      const content1 = await TemplateRegistry.getTemplate(templateName, TEMPLATES_DIR);
      const content2 = await TemplateRegistry.getTemplate(templateName, TEMPLATES_DIR);
      const content3 = await TemplateRegistry.getTemplate(templateName, TEMPLATES_DIR);

      // All calls should return identical content
      expect(content1).toBe(content2);
      expect(content2).toBe(content3);
    });
  });
});
