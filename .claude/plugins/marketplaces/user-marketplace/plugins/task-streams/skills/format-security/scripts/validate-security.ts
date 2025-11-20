#!/usr/bin/env tsx
/**
 * Validates that a security has all 10 required enrichments
 *
 * Usage:
 *   tsx scripts/validate-security.ts <security-file.md>
 *   tsx scripts/validate-security.ts --stdin < security.md
 *
 * Exit codes:
 *   0 - All validations passed
 *   1 - Validation failures found
 *   2 - Invalid usage or file error
 */

import * as fs from "fs";
import * as path from "path";

interface ValidationResult {
  passed: boolean;
  message: string;
  severity: "error" | "warning";
}

interface SecurityValidation {
  security: string;
  results: ValidationResult[];
  passed: boolean;
  errors: number;
  warnings: number;
}

class SecurityValidator {
  private security: string;

  constructor(security: string) {
    this.security = security;
  }

  validate(): SecurityValidation {
    const results: ValidationResult[] = [
      this.validateComponent(),
      this.validateFileLocations(),
      this.validateEffortEstimate(),
      this.validateComplexity(),
      this.validateRegressionRisk(),
      this.validateRegressionRiskDetails(),
      this.validateAcceptanceCriteria(),
      this.validateImplementationSteps(),
      this.validateCodeExamples(),
      this.validateFileChangeScope(),
      this.validateTestingTable(),
      this.validateDependencies(),
    ];

    const errors = results.filter((r) => !r.passed && r.severity === "error").length;
    const warnings = results.filter((r) => !r.passed && r.severity === "warning").length;

    return {
      security: this.security.substring(0, 100) + "...",
      results,
      passed: errors === 0,
      errors,
      warnings,
    };
  }

  // Enrichment 1: Component classification
  private validateComponent(): ValidationResult {
    const hasComponent = /\*\*Component:\*\*\s+C\d{2}:/i.test(this.security);
    return {
      passed: hasComponent,
      message: hasComponent
        ? "✓ Component code found (C##: Name format)"
        : "✗ Missing component code (expected: C##: Name)",
      severity: "error",
    };
  }

  // Enrichment 2: File locations with line numbers
  private validateFileLocations(): ValidationResult {
    const hasLocation = /\*\*Location:\*\*\s+`[^`]+:\d+-\d+`/.test(this.security);
    return {
      passed: hasLocation,
      message: hasLocation
        ? "✓ File location found with line ranges"
        : "✗ Missing file location with line ranges (expected: `file.ts:start-end`)",
      severity: "error",
    };
  }

  // Enrichment 3: Effort estimates
  private validateEffortEstimate(): ValidationResult {
    const hasEffort = /\*\*Estimated Effort:\*\*\s+\d+(\.\d+)?h/.test(this.security);
    return {
      passed: hasEffort,
      message: hasEffort
        ? "✓ Effort estimate found"
        : "✗ Missing effort estimate (expected: Xh format)",
      severity: "error",
    };
  }

  // Enrichment 4: Complexity classification
  private validateComplexity(): ValidationResult {
    const hasComplexity = /\*\*Complexity:\*\*\s+(CRITICAL|HIGH|MEDIUM|LOW)/.test(this.security);
    return {
      passed: hasComplexity,
      message: hasComplexity
        ? "✓ Complexity classification found"
        : "✗ Missing complexity (expected: CRITICAL|HIGH|MEDIUM|LOW)",
      severity: "error",
    };
  }

  // Enrichment 5: Regression risk level
  private validateRegressionRisk(): ValidationResult {
    const hasRisk = /\*\*Regression Risk:\*\*\s+(HIGH|MEDIUM|LOW)/.test(this.security);
    return {
      passed: hasRisk,
      message: hasRisk
        ? "✓ Regression risk level found"
        : "✗ Missing regression risk level (expected: HIGH|MEDIUM|LOW)",
      severity: "error",
    };
  }

  // Enrichment 5 (continued): Regression risk details (5 dimensions)
  private validateRegressionRiskDetails(): ValidationResult {
    const hasImpact = /\*\*Impact:\*\*/.test(this.security);
    const hasBlastRadius = /\*\*Blast Radius:\*\*/.test(this.security);
    const hasDependencies = /\*\*Dependencies:\*\*/.test(this.security);
    const hasTestingGaps = /\*\*Testing Gaps:\*\*/.test(this.security);
    const hasRollbackRisk = /\*\*Rollback Risk:\*\*/.test(this.security);

    const dimensions = [
      hasImpact && "Impact",
      hasBlastRadius && "Blast Radius",
      hasDependencies && "Dependencies",
      hasTestingGaps && "Testing Gaps",
      hasRollbackRisk && "Rollback Risk",
    ].filter(Boolean);

    const passed = dimensions.length === 5;

    return {
      passed,
      message: passed
        ? "✓ All 5 regression risk dimensions found"
        : `✗ Missing regression risk dimensions: ${5 - dimensions.length} missing (found: ${dimensions.join(", ")})`,
      severity: "error",
    };
  }

  // Enrichment 6: Acceptance criteria (minimum 3)
  private validateAcceptanceCriteria(): ValidationResult {
    const criteriaMatches = this.security.match(/- \[ \]/g);
    const count = criteriaMatches ? criteriaMatches.length : 0;
    const passed = count >= 3;

    return {
      passed,
      message: passed
        ? `✓ Acceptance criteria found (${count} items)`
        : `✗ Insufficient acceptance criteria (found: ${count}, minimum: 3)`,
      severity: count >= 1 ? "warning" : "error",
    };
  }

  // Enrichment 7: Implementation steps (minimum 3)
  private validateImplementationSteps(): ValidationResult {
    const stepsSection = this.security.match(/\*\*Implementation Steps:\*\*([\s\S]*?)(?=\*\*|$)/i);
    if (!stepsSection) {
      return {
        passed: false,
        message: "✗ Missing Implementation Steps section",
        severity: "error",
      };
    }

    const steps = stepsSection[1].match(/^\d+\./gm);
    const count = steps ? steps.length : 0;
    const passed = count >= 3;

    return {
      passed,
      message: passed
        ? `✓ Implementation steps found (${count} steps)`
        : `✗ Insufficient implementation steps (found: ${count}, minimum: 3)`,
      severity: count >= 1 ? "warning" : "error",
    };
  }

  // Enrichment 8: Code examples (optional but recommended)
  private validateCodeExamples(): ValidationResult {
    const hasCurrent = /\*\*Current Code.*?\*\*:[\s\S]*?```/i.test(this.security);
    const hasProposed = /\*\*Proposed.*?\*\*:[\s\S]*?```/i.test(this.security);
    const passed = hasCurrent && hasProposed;

    return {
      passed,
      message: passed
        ? "✓ Code examples found (current + proposed)"
        : "⚠ Code examples missing or incomplete (recommended for code changes)",
      severity: "warning",
    };
  }

  // Enrichment 9: File change scope (3 categories)
  private validateFileChangeScope(): ValidationResult {
    const hasCreate = /\*\*Files to Create:\*\*/i.test(this.security);
    const hasModify = /\*\*Files to Modify:\*\*/i.test(this.security);
    const hasDelete = /\*\*Files to Delete:\*\*/i.test(this.security);

    const categories = [hasCreate, hasModify, hasDelete].filter(Boolean).length;
    const passed = categories === 3;

    return {
      passed,
      message: passed
        ? "✓ All 3 file change categories found (Create/Modify/Delete)"
        : `✗ Missing file change categories (found: ${categories}, required: 3)`,
      severity: "error",
    };
  }

  // Enrichment 10: Testing table
  private validateTestingTable(): ValidationResult {
    const hasTable = /\| Test Type.*\| Validates AC.*\| Description.*\| Location.*\|/i.test(
      this.security
    );
    if (!hasTable) {
      return { passed: false, message: "✗ Missing testing table", severity: "error" };
    }

    const tableRows = this.security.match(/\| (Unit|Integration|E2E)/gi);
    const rowCount = tableRows ? tableRows.length : 0;

    return {
      passed: rowCount > 0,
      message:
        rowCount > 0
          ? `✓ Testing table found (${rowCount} test types)`
          : "✗ Testing table exists but has no test rows",
      severity: "error",
    };
  }

  // Enrichment 11: Dependencies and prerequisites
  private validateDependencies(): ValidationResult {
    const hasBlocking = /\*\*Blocking Dependencies:\*\*/i.test(this.security);
    const hasBlocks = /\*\*Blocks:\*\*/i.test(this.security);
    const hasPrereqs = /\*\*Prerequisites:\*\*/i.test(this.security);

    const sections = [hasBlocking, hasBlocks, hasPrereqs].filter(Boolean).length;
    const passed = sections === 3;

    return {
      passed,
      message: passed
        ? "✓ All dependency sections found (Blocking/Blocks/Prerequisites)"
        : `✗ Missing dependency sections (found: ${sections}, required: 3)`,
      severity: "error",
    };
  }
}

// CLI Interface
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log(`
Usage:
  tsx scripts/validate-security.ts <security-file.md>
  tsx scripts/validate-security.ts --stdin < security.md

Options:
  --help, -h    Show this help message
  --stdin       Read security from stdin instead of file

Exit codes:
  0 - All validations passed
  1 - Validation failures found
  2 - Invalid usage or file error
`);
    process.exit(0);
  }

  let security: string;

  if (args.includes("--stdin")) {
    // Read from stdin
    const chunks: Buffer[] = [];
    process.stdin.on("data", (chunk) => chunks.push(chunk));
    process.stdin.on("end", () => {
      security = Buffer.concat(chunks).toString("utf-8");
      runValidation(security);
    });
  } else {
    // Read from file
    const filePath = args[0];
    if (!fs.existsSync(filePath)) {
      console.error(`Error: File not found: ${filePath}`);
      process.exit(2);
    }

    try {
      security = fs.readFileSync(filePath, "utf-8");
      runValidation(security);
    } catch (error) {
      console.error(`Error reading file: ${error}`);
      process.exit(2);
    }
  }
}

function runValidation(security: string) {
  const validator = new SecurityValidator(security);
  const result = validator.validate();

  console.log("\n=== Security Validation Results ===\n");
  console.log(`Security: ${result.security}`);
  console.log();

  // Group results by status
  const errors = result.results.filter((r) => !r.passed && r.severity === "error");
  const warnings = result.results.filter((r) => !r.passed && r.severity === "warning");
  const passed = result.results.filter((r) => r.passed);

  // Print errors
  if (errors.length > 0) {
    console.log("ERRORS:");
    errors.forEach((r) => console.log(`  ${r.message}`));
    console.log();
  }

  // Print warnings
  if (warnings.length > 0) {
    console.log("WARNINGS:");
    warnings.forEach((r) => console.log(`  ${r.message}`));
    console.log();
  }

  // Print passed checks
  if (passed.length > 0) {
    console.log("PASSED:");
    passed.forEach((r) => console.log(`  ${r.message}`));
    console.log();
  }

  // Summary
  console.log("=== Summary ===");
  console.log(`Total checks: ${result.results.length}`);
  console.log(`Passed: ${passed.length}`);
  console.log(`Errors: ${result.errors}`);
  console.log(`Warnings: ${result.warnings}`);
  console.log();

  if (result.passed) {
    console.log("✅ All required enrichments present!");
    process.exit(0);
  } else {
    console.log("❌ Validation failed - missing required enrichments");
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { SecurityValidator, ValidationResult, SecurityValidation };
