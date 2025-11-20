/**
 * Template Registry (Task 1.8 - GREEN Phase)
 *
 * Discovery API for managing and querying task templates
 * Implements TemplateRegistry class with static methods for template operations
 */

import { readdir, readFile } from 'fs/promises'
import { join, resolve } from 'path'
import { parse as parseYaml } from 'yaml'
import { validateTemplateHasAllEnrichments } from './template-enrichment-validator.js'

export interface TemplateMetadata {
  templateName: string
  templateVersion: string
  description: string
  requiredEnrichments: number
  formatSkill: string
  path: string
}

/**
 * TemplateRegistry class for discovering and managing templates
 */
export class TemplateRegistry {
  /**
   * Get default templates directory
   */
  private static defaultTemplatesDir(): string {
    return join(process.cwd(), '.claude-plugins/task-streams/templates')
  }

  /**
   * Extract YAML frontmatter from template content
   * Frontmatter is delimited by --- at start and end
   */
  private static extractFrontmatter(content: string): Record<string, unknown> {
    const lines = content.split('\n')
    const firstLine = lines[0]?.trim()

    if (firstLine !== '---') {
      throw new Error('Template missing frontmatter (must start with ---)')
    }

    // Find closing ---
    let endIndex = -1
    for (let i = 1; i < lines.length; i++) {
      if (lines[i]?.trim() === '---') {
        endIndex = i
        break
      }
    }

    if (endIndex === -1) {
      throw new Error('Template frontmatter not closed (missing ending ---)')
    }

    // Extract YAML content between delimiters
    const yamlContent = lines.slice(1, endIndex).join('\n')

    try {
      const parsed = parseYaml(yamlContent) as Record<string, unknown>
      return parsed
    } catch (error) {
      throw new Error(
        `Failed to parse template frontmatter YAML: ${error instanceof Error ? error.message : String(error)}`
      )
    }
  }

  /**
   * List all templates in the templates directory
   * Returns array of template metadata sorted by templateName
   *
   * @param templatesDir - Directory containing templates (defaults to .claude-plugins/task-streams/templates)
   * @returns Array of template metadata objects
   */
  static async listTemplates(templatesDir?: string): Promise<TemplateMetadata[]> {
    const dir = templatesDir ?? this.defaultTemplatesDir()

    try {
      const files = await readdir(dir)

      // Filter for .template.md files only
      const templateFiles = files.filter((file) => file.endsWith('.template.md'))

      const templates: TemplateMetadata[] = []

      for (const file of templateFiles) {
        const filePath = join(dir, file)
        const content = await readFile(filePath, 'utf-8')

        try {
          const frontmatter = this.extractFrontmatter(content)

          templates.push({
            templateName: String(frontmatter.templateName ?? ''),
            templateVersion: String(frontmatter.templateVersion ?? ''),
            description: String(frontmatter.description ?? ''),
            requiredEnrichments: Number(frontmatter.requiredEnrichments ?? 0),
            formatSkill: String(frontmatter.formatSkill ?? ''),
            path: resolve(filePath),
          })
        } catch (error) {
          // Re-throw with file context
          throw new Error(
            `Error processing template "${file}": ${error instanceof Error ? error.message : String(error)}`
          )
        }
      }

      // Sort by templateName
      return templates.sort((a, b) => a.templateName.localeCompare(b.templateName))
    } catch (error) {
      if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
        // Directory doesn't exist - return empty array
        return []
      }
      throw error
    }
  }

  /**
   * Get template content by name
   *
   * @param name - Template name (without .template.md extension)
   * @param templatesDir - Directory containing templates
   * @returns Full template content as string
   * @throws Error if template not found
   */
  static async getTemplate(name: string, templatesDir?: string): Promise<string> {
    const dir = templatesDir ?? this.defaultTemplatesDir()
    const filePath = join(dir, `${name}.template.md`)

    try {
      const content = await readFile(filePath, 'utf-8')
      return content
    } catch (error) {
      if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
        throw new Error(
          `Template "${name}" not found at path: ${filePath}\n` +
            `Make sure the file ${name}.template.md exists in the templates directory.`
        )
      }
      throw error
    }
  }

  /**
   * Get template metadata only (not full content)
   *
   * @param name - Template name (without .template.md extension)
   * @param templatesDir - Directory containing templates
   * @returns Template metadata object
   * @throws Error if template not found
   */
  static async getTemplateMetadata(name: string, templatesDir?: string): Promise<TemplateMetadata> {
    const dir = templatesDir ?? this.defaultTemplatesDir()
    const filePath = join(dir, `${name}.template.md`)

    // Get full content first
    const content = await this.getTemplate(name, templatesDir)

    // Extract frontmatter
    const frontmatter = this.extractFrontmatter(content)

    return {
      templateName: String(frontmatter.templateName ?? ''),
      templateVersion: String(frontmatter.templateVersion ?? ''),
      description: String(frontmatter.description ?? ''),
      requiredEnrichments: Number(frontmatter.requiredEnrichments ?? 0),
      formatSkill: String(frontmatter.formatSkill ?? ''),
      path: resolve(filePath),
    }
  }

  /**
   * Validate template has all required enrichments
   *
   * @param name - Template name (without .template.md extension)
   * @param templatesDir - Directory containing templates
   * @returns true if template is valid, false otherwise
   * @throws Error if template not found
   */
  static async validateTemplate(name: string, templatesDir?: string): Promise<boolean> {
    // Get template content
    const content = await this.getTemplate(name, templatesDir)

    // Use enrichment validator
    const validation = validateTemplateHasAllEnrichments(content)

    return validation.passed
  }
}
