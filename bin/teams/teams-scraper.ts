#!/usr/bin/env bun
/**
 * Microsoft Teams Chat Scraper POC
 *
 * Extracts chat messages from Microsoft Teams via clipboard capture.
 * Parses the raw text into structured JSON with metadata.
 *
 * Usage:
 *   1. Open Teams to the desired channel
 *   2. Run: bun teams-scraper.ts [--channel "🏆Engineers"] [--output ./output.json]
 *   3. Script will capture, parse, and save messages
 */

import { $ } from "bun"
import { parseArgs } from "util"

const DEBUG_REPLIES = false

interface TeamsMessage {
  id: string
  author: string
  timestamp: string
  date: string
  time: string
  content: string
  isReply: boolean
  replyTo?: {
    author: string
    timestamp: string
    preview: string
  }
  reactions: Reaction[]
  attachments: Attachment[]
  mentions: string[]
}

interface Reaction {
  emoji: string
  name: string
  count: number
}

interface Attachment {
  type: "image" | "gif" | "link" | "file" | "praise"
  description: string
  url?: string
}

interface ScrapedData {
  channel: string
  scrapedAt: string
  messageCount: number
  dateRange: {
    earliest: string
    latest: string
  }
  messages: TeamsMessage[]
}

/**
 * Captures Teams chat content via clipboard
 */
async function captureTeamsContent(): Promise<string> {
  console.log("📋 Activating Teams and capturing content...")

  // Activate Teams
  await $`osascript -e 'tell application "Microsoft Teams" to activate'`
  await Bun.sleep(500)

  // Select all and copy
  await $`osascript -e 'tell application "System Events" to keystroke "a" using command down'`
  await Bun.sleep(300)
  await $`osascript -e 'tell application "System Events" to keystroke "c" using command down'`
  await Bun.sleep(500)

  // Deselect
  await $`osascript -e 'tell application "System Events" to key code 53'`

  // Get clipboard content
  const result = await $`pbpaste`.text()
  return result
}

/**
 * Parses raw Teams clipboard text into structured messages
 */
function parseTeamsContent(raw: string): ScrapedData {
  const lines = raw.split("\n")
  const messages: TeamsMessage[] = []

  // Extract channel name from the raw content
  const channelMatch = raw.match(/^([🏆🎯📊🔧💡][^\n]+)\n\n\nChat/m)
  const channel = channelMatch ? channelMatch[1].trim() : "Unknown Channel"

  // Message pattern: "Author\nDD/MM/YYYY H:MM am/pm\n\nContent"
  // Or reply pattern: "Begin Reference, ... by Author\nAuthor\nDD/MM/YYYY..."
  const messageRegex =
    /^(?:Begin Reference, (.+?) by ([^\n]+)\n)?([A-Za-z][A-Za-z\s]+)\n(\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m)\n\n([\s\S]*?)(?=\n\n(?:[A-Za-z][A-Za-z\s]+\n\d{2}\/\d{2}\/\d{4}|Begin Reference|$))/gm

  // Find the start of actual messages (after UI chrome)
  const messageStartIndex = raw.indexOf("\n\n\n")
  if (messageStartIndex === -1) {
    return {
      channel,
      scrapedAt: new Date().toISOString(),
      messageCount: 0,
      dateRange: { earliest: "", latest: "" },
      messages: [],
    }
  }

  const messageContent = raw.substring(messageStartIndex)

  // Split by message blocks - each message starts with "by AuthorName" pattern
  // or just "AuthorName\nDate" pattern
  const messageBlocks = splitIntoMessageBlocks(messageContent)

  for (const block of messageBlocks) {
    const message = parseMessageBlock(block)
    if (message) {
      messages.push(message)
    }
  }

  // Calculate date range
  const dates = messages
    .map((m) => parseDate(m.timestamp))
    .filter((d) => d !== null) as Date[]

  const earliest = dates.length > 0 ? new Date(Math.min(...dates.map((d) => d.getTime()))) : null
  const latest = dates.length > 0 ? new Date(Math.max(...dates.map((d) => d.getTime()))) : null

  return {
    channel,
    scrapedAt: new Date().toISOString(),
    messageCount: messages.length,
    dateRange: {
      earliest: earliest ? earliest.toISOString().split("T")[0] : "",
      latest: latest ? latest.toISOString().split("T")[0] : "",
    },
    messages,
  }
}

/**
 * Splits raw content into individual message blocks
 */
function splitIntoMessageBlocks(content: string): string[] {
  const blocks: string[] = []

  // Pattern to identify message headers
  // Format: "Content preview... by AuthorName\nAuthorName\nDD/MM/YYYY H:MM am/pm"
  // Or: "AuthorName\nDD/MM/YYYY H:MM am/pm"
  const headerPattern = /(?:^|\n\n)(?:(?:[^\n]+ by [A-Za-z][A-Za-z\s]+\n)?([A-Za-z][A-Za-z\s]+)\n(\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m))/g

  let lastIndex = 0
  let match: RegExpExecArray | null

  const matches: { index: number; length: number }[] = []

  while ((match = headerPattern.exec(content)) !== null) {
    // Validate this looks like a real message header
    const author = match[1]
    const timestamp = match[2]

    if (author && timestamp && isValidAuthor(author)) {
      matches.push({ index: match.index, length: match[0].length })
    }
  }

  // Extract blocks between matches
  for (let i = 0; i < matches.length; i++) {
    const start = matches[i].index
    const end = i < matches.length - 1 ? matches[i + 1].index : content.length
    const block = content.substring(start, end).trim()
    if (block) {
      blocks.push(block)
    }
  }

  return blocks
}

/**
 * Checks if a string looks like a valid author name
 */
function isValidAuthor(name: string): boolean {
  // Filter out UI elements that look like names
  const invalidNames = [
    "Chat",
    "Channels",
    "Chats",
    "Meeting",
    "Unread",
    "Has context menu",
    "Last read",
    "Jump to newest",
    "Meet now",
    "Sign in",
    "See more",
  ]

  const trimmed = name.trim()
  if (invalidNames.some((invalid) => trimmed.includes(invalid))) {
    return false
  }

  // Must have at least first and last name pattern
  return /^[A-Z][a-z]+ [A-Z][a-z]+/.test(trimmed)
}

/**
 * Parses a single message block into a TeamsMessage
 */
function parseMessageBlock(block: string): TeamsMessage | null {
  const lines = block.split("\n")

  // Find author and timestamp lines
  let authorIndex = -1
  let author = ""
  let timestamp = ""

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    const nextLine = lines[i + 1]?.trim() || ""

    // Check if this line is an author followed by a timestamp
    if (isValidAuthor(line) && /^\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m$/.test(nextLine)) {
      author = line
      timestamp = nextLine
      authorIndex = i
      break
    }
  }

  if (!author || !timestamp || authorIndex === -1) {
    return null
  }

  // Check for reply reference
  let isReply = false
  let replyTo: TeamsMessage["replyTo"] = undefined

  const firstLine = lines[0]?.trim() || ""
  if (firstLine.startsWith("Begin Reference,")) {
    isReply = true
    // Parse reply reference: "Begin Reference, preview... by Author"
    const refMatch = firstLine.match(/Begin Reference, (.+?) by ([A-Za-z][A-Za-z\s]+)$/)
    if (refMatch) {
      // Look for the referenced author's timestamp
      const refAuthor = refMatch[2].trim()
      const refPreview = refMatch[1].trim()

      // Find the original timestamp in the block
      for (let i = 1; i < authorIndex; i++) {
        if (lines[i].trim() === refAuthor) {
          const refTimestamp = lines[i + 1]?.trim() || ""
          if (/^\d{2}\/\d{2}\/\d{4}/.test(refTimestamp)) {
            replyTo = {
              author: refAuthor,
              timestamp: refTimestamp,
              preview: refPreview,
            }
            break
          }
        }
      }
    }
  }

  // Extract content (everything after timestamp line until reactions)
  const contentStartIndex = authorIndex + 2 // Skip author and timestamp
  const contentLines: string[] = []
  const reactions: Reaction[] = []
  const attachments: Attachment[] = []

  for (let i = contentStartIndex; i < lines.length; i++) {
    const line = lines[i]

    // Check for reaction patterns
    const reactionMatch = line.match(/^(\d+) ([A-Za-z\s]+) reactions?\.?$/)
    if (reactionMatch) {
      reactions.push({
        emoji: "",
        name: reactionMatch[2].trim(),
        count: parseInt(reactionMatch[1]),
      })
      continue
    }

    // Check for emoji + count pattern
    const emojiReactionMatch = line.match(/^([^\w\s])$/)
    const nextLine = lines[i + 1]?.trim() || ""
    if (emojiReactionMatch && /^\d+ [A-Za-z]/.test(nextLine)) {
      const countMatch = nextLine.match(/^(\d+) ([A-Za-z\s]+) reactions?/)
      if (countMatch) {
        reactions.push({
          emoji: emojiReactionMatch[1],
          name: countMatch[2].trim(),
          count: parseInt(countMatch[1]),
        })
        i++ // Skip the count line
        continue
      }
    }

    // Check for attachments
    if (line.includes("(GIF Image)")) {
      attachments.push({ type: "gif", description: line })
      continue
    }
    if (line.includes("Url Preview for")) {
      attachments.push({
        type: "link",
        description: line.replace("Url Preview for ", ""),
      })
      continue
    }
    if (line.includes("Praise card sent")) {
      attachments.push({ type: "praise", description: line })
      continue
    }
    if (line.includes("has an attachment")) {
      attachments.push({ type: "file", description: line })
      continue
    }

    // Regular content
    if (line.trim() && !line.match(/^\d+$/)) {
      contentLines.push(line)
    }
  }

  // Extract mentions from content
  const content = contentLines.join("\n").trim()
  const mentions = extractMentions(content)

  // Parse date components
  const [datePart, timePart] = timestamp.split(" ")
  const time = `${timePart} ${timestamp.split(" ")[2]}`

  // Generate unique ID
  const id = generateMessageId(author, timestamp)

  return {
    id,
    author,
    timestamp,
    date: datePart,
    time,
    content,
    isReply,
    replyTo,
    reactions,
    attachments,
    mentions,
  }
}

/**
 * Extracts @mentions from message content
 */
function extractMentions(content: string): string[] {
  const mentions: string[] = []

  // Pattern for explicit mentions (names without @)
  // Teams shows "FirstName LastName" or just "FirstName" for mentions
  // Usually followed by comma or space

  // Check for "Everyone" mention
  if (content.includes("Everyone")) {
    mentions.push("Everyone")
  }

  // Look for name patterns that appear to be mentions
  // This is heuristic - names at start of sentences or after commas
  const namePattern = /(?:^|,\s*)([A-Z][a-z]+ [A-Z][a-z]+)(?=\s|,|$|\?)/g
  let match: RegExpExecArray | null
  while ((match = namePattern.exec(content)) !== null) {
    const name = match[1]
    if (!mentions.includes(name) && isValidAuthor(name)) {
      mentions.push(name)
    }
  }

  return mentions
}

/**
 * Generates a unique message ID
 */
function generateMessageId(author: string, timestamp: string): string {
  const authorSlug = author.toLowerCase().replace(/\s+/g, "-")
  const timeSlug = timestamp.replace(/[\/\s:]/g, "").replace(/[ap]m/i, "")
  return `${authorSlug}-${timeSlug}`
}

/**
 * Parses DD/MM/YYYY timestamp to Date
 */
function parseDate(timestamp: string): Date | null {
  const match = timestamp.match(/(\d{2})\/(\d{2})\/(\d{4}) (\d{1,2}):(\d{2}) ([ap]m)/i)
  if (!match) return null

  const [, day, month, year, hour, minute, ampm] = match
  let h = parseInt(hour)
  if (ampm.toLowerCase() === "pm" && h !== 12) h += 12
  if (ampm.toLowerCase() === "am" && h === 12) h = 0

  return new Date(parseInt(year), parseInt(month) - 1, parseInt(day), h, parseInt(minute))
}

/**
 * Alternative simpler parser that handles the actual format better
 */
function parseTeamsContentSimple(raw: string): ScrapedData {
  const messages: TeamsMessage[] = []

  // Extract channel name
  const channelMatch = raw.match(/^([🏆🎯📊🔧💡][^\n]+)\n/m)
  const channel = channelMatch ? channelMatch[1].trim() : "Unknown Channel"

  // More robust pattern matching
  // Each message block pattern:
  // [optional: "Begin Reference, preview by Author\nAuthor\ntimestamp\noriginal content"]
  // Author Name
  // DD/MM/YYYY H:MM am/pm
  // [blank line]
  // Content...
  // [reactions]

  const regex =
    /(?:Begin Reference, ([^\n]+) by ([A-Za-z][A-Za-z ]+)\n([A-Za-z][A-Za-z ]+)\n(\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m)\n([^\n]*)\n)?([A-Za-z][A-Za-z ]+)\n(\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m)\n\n([\s\S]*?)(?=\n\n(?:[A-Za-z][A-Za-z ]+ by [A-Za-z]|[A-Za-z][A-Za-z ]+\n\d{2}\/\d{2}\/\d{4}|Begin Reference|Last read|has context menu|$))/g

  let match: RegExpExecArray | null
  let msgIndex = 0

  while ((match = regex.exec(raw)) !== null) {
    const [
      fullMatch,
      refPreview,
      refByAuthor,
      refOrigAuthor,
      refTimestamp,
      refContent,
      author,
      timestamp,
      contentBlock,
    ] = match

    if (!isValidAuthor(author)) continue

    // Parse content and reactions
    const { content, reactions, attachments } = parseContentBlock(contentBlock || "")

    const [datePart] = timestamp.split(" ")
    const timePart = timestamp.replace(datePart + " ", "")

    const message: TeamsMessage = {
      id: generateMessageId(author, timestamp),
      author,
      timestamp,
      date: datePart,
      time: timePart,
      content,
      isReply: !!refPreview,
      replyTo: refPreview
        ? {
            author: refOrigAuthor || refByAuthor,
            timestamp: refTimestamp || "",
            preview: refPreview,
          }
        : undefined,
      reactions,
      attachments,
      mentions: extractMentions(content),
    }

    messages.push(message)
    msgIndex++
  }

  // Calculate date range
  const dates = messages.map((m) => parseDate(m.timestamp)).filter((d) => d !== null) as Date[]

  return {
    channel,
    scrapedAt: new Date().toISOString(),
    messageCount: messages.length,
    dateRange: {
      earliest: dates.length > 0 ? new Date(Math.min(...dates.map((d) => d.getTime()))).toISOString().split("T")[0] : "",
      latest: dates.length > 0 ? new Date(Math.max(...dates.map((d) => d.getTime()))).toISOString().split("T")[0] : "",
    },
    messages,
  }
}

/**
 * Parses content block to extract content, reactions, and attachments
 */
function parseContentBlock(block: string): {
  content: string
  reactions: Reaction[]
  attachments: Attachment[]
} {
  const lines = block.split("\n")
  const contentLines: string[] = []
  const reactions: Reaction[] = []
  const attachments: Attachment[] = []

  let i = 0
  while (i < lines.length) {
    const line = lines[i]
    const trimmed = line.trim()

    // Skip empty lines at the start
    if (!trimmed && contentLines.length === 0) {
      i++
      continue
    }

    // Check for reaction emoji line followed by count
    if (trimmed.length <= 4 && /[^\w\s]/.test(trimmed)) {
      const nextLine = lines[i + 1]?.trim() || ""
      const countMatch = nextLine.match(/^(\d+) ([A-Za-z\s-]+) reactions?\.?/)
      if (countMatch) {
        reactions.push({
          emoji: trimmed,
          name: countMatch[2].trim(),
          count: parseInt(countMatch[1]),
        })
        i += 2
        continue
      }
    }

    // Check for single reaction count line
    const singleReactionMatch = trimmed.match(/^(\d+) ([A-Za-z\s-]+) reactions?\.?$/)
    if (singleReactionMatch) {
      reactions.push({
        emoji: "",
        name: singleReactionMatch[2].trim(),
        count: parseInt(singleReactionMatch[1]),
      })
      i++
      continue
    }

    // Check for just a number (reaction count without name)
    if (/^\d+$/.test(trimmed) && reactions.length > 0) {
      i++
      continue
    }

    // Check for GIF/image attachments
    if (trimmed.includes("(GIF Image)") || trimmed.includes("GIF by")) {
      attachments.push({ type: "gif", description: trimmed })
      i++
      continue
    }

    // Check for URL previews
    if (trimmed.startsWith("Url Preview for")) {
      attachments.push({
        type: "link",
        description: trimmed.replace("Url Preview for ", ""),
      })
      i++
      continue
    }

    // Check for praise cards
    if (trimmed.includes("Praise card sent") || trimmed.includes("Praise")) {
      attachments.push({ type: "praise", description: trimmed })
      i++
      continue
    }

    // Check for file attachments
    if (trimmed.includes("has an attachment")) {
      attachments.push({ type: "file", description: trimmed })
      i++
      continue
    }

    // Regular content line
    contentLines.push(line)
    i++
  }

  return {
    content: contentLines
      .join("\n")
      .trim()
      .replace(/\n{3,}/g, "\n\n"),
    reactions,
    attachments,
  }
}

/**
 * Line-by-line state machine parser (most reliable)
 *
 * Teams clipboard format:
 * - Each message has a "preview header": "Content preview... by AuthorName"
 * - Followed by: AuthorName\nDD/MM/YYYY H:MM am/pm\n\nActual content
 * - Reactions appear as: emoji\nN emoji-name reactions.\nN
 * - Replies start with "Begin Reference,"
 */
function parseTeamsStateMachine(raw: string): ScrapedData {
  const messages: TeamsMessage[] = []

  // Find channel name
  const channelMatch = raw.match(/([🏆🎯📊🔧💡][^\n]+)\n/)
  const channel = channelMatch ? channelMatch[1].trim() : "Unknown Channel"

  const lines = raw.split("\n")
  const timestampRegex = /^(\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} [ap]m)$/

  // State machine
  type ParseState = "seeking" | "found_preview" | "found_author" | "reading_content" | "reading_reply_content"
  let state: ParseState = "seeking"
  let skipQuotedLines = 0 // Counter to skip quoted content in replies

  let currentAuthor = ""
  let currentTimestamp = ""
  let currentContent: string[] = []
  let currentReactions: Reaction[] = []
  let currentAttachments: Attachment[] = []
  let isReply = false
  let replyTo: TeamsMessage["replyTo"] = undefined
  let skipNextPreview = false // Flag to skip preview lines that bleed into content

  // Helper to check if a line is a "preview by Author" header
  const isPreviewHeader = (line: string): boolean => {
    return / by [A-Z][a-z]+ [A-Z][a-z]+$/.test(line) && !line.startsWith("Begin Reference")
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const trimmed = line.trim()
    const nextLine = lines[i + 1]?.trim() || ""
    const lineAfterNext = lines[i + 2]?.trim() || ""

    // Debug: Check for Begin Reference anywhere
    if (DEBUG_REPLIES && trimmed.startsWith("Begin Reference,")) {
      console.log(`[DEBUG] Line ${i}: Begin Reference found, current state: ${state}`)
    }

    // Skip UI chrome at the top
    if (state === "seeking") {
      if (
        trimmed === "" ||
        trimmed === "Chat" ||
        trimmed === "Shared" ||
        trimmed === "Has context menu" ||
        trimmed === "Meet now" ||
        trimmed === "Unread" ||
        trimmed === "Channels" ||
        trimmed === "Chats" ||
        trimmed === "Meeting chats" ||
        trimmed.includes("Sign in") ||
        trimmed.includes("notifications") ||
        /^\d+$/.test(trimmed)
      ) {
        continue
      }
    }

    switch (state) {
      case "seeking":
        // Check for reply reference (Begin Reference,)
        // Format: "Begin Reference, preview by ReplyAuthor"
        // Then: ReplyAuthor\nTimestamp\n\nOriginalAuthor\nTimestamp\nQuotedContent\nActualReplyContent
        if (trimmed.startsWith("Begin Reference,")) {
          if (DEBUG_REPLIES) console.log(`[DEBUG] Line ${i}: Found Begin Reference in seeking state`)
          const refMatch = trimmed.match(/Begin Reference, (.+) by ([A-Z][a-z]+ [A-Z][a-z ]+)$/)
          if (refMatch) {
            const replyAuthor = refMatch[2].trim()
            const preview = refMatch[1].trim()
            if (DEBUG_REPLIES) console.log(`[DEBUG]   Reply author: ${replyAuthor}, preview: ${preview.substring(0, 30)}...`)

            // Save any previous message
            if (currentAuthor && currentTimestamp && (currentContent.length > 0 || currentReactions.length > 0)) {
              if (DEBUG_REPLIES) console.log(`[DEBUG]   Saving previous message: ${currentAuthor} (isReply: ${isReply})`)
              messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
            }

            // Find reply author line and original author line
            let replyTimestamp = ""
            let originalAuthor = ""
            let originalTimestamp = ""
            let originalAuthorLineIndex = -1
            let foundReplyAuthorLine = false

            for (let j = i + 1; j < Math.min(i + 15, lines.length); j++) {
              const scanLine = lines[j]?.trim() || ""
              const scanNextLine = lines[j + 1]?.trim() || ""

              // Find reply author (first author match)
              if (!foundReplyAuthorLine && scanLine === replyAuthor && timestampRegex.test(scanNextLine)) {
                replyTimestamp = scanNextLine
                foundReplyAuthorLine = true
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Found reply timestamp: ${replyTimestamp}`)
                continue
              }

              // Find original author (second author match - can be same person for self-replies)
              if (foundReplyAuthorLine && !originalAuthor && isValidAuthor(scanLine) && timestampRegex.test(scanNextLine)) {
                originalAuthor = scanLine
                originalTimestamp = scanNextLine
                originalAuthorLineIndex = j
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Found original author: ${originalAuthor} at line ${j}`)
                break
              }
            }

            if (replyTimestamp && originalAuthor) {
              if (DEBUG_REPLIES) console.log(`[DEBUG]   Setting up reply: ${replyAuthor} replying to ${originalAuthor}`)
              // Set up the reply message
              currentAuthor = replyAuthor
              currentTimestamp = replyTimestamp
              currentContent = []
              currentReactions = []
              currentAttachments = []
              isReply = true
              skipQuotedLines = 0 // Reset quoted line counter
              replyTo = {
                author: originalAuthor,
                timestamp: originalTimestamp,
                preview: preview,
              }

              // Skip ahead past the quoted content
              // We need to find where the quoted content ends
              // It ends when we hit a new preview header, new author line, or reactions
              if (originalAuthorLineIndex > 0) {
                // Skip to after original author's timestamp line
                i = originalAuthorLineIndex + 1 // Will be incremented by for loop
                state = "reading_reply_content"
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Transitioning to reading_reply_content, i=${i}`)
              }
            } else {
              if (DEBUG_REPLIES) console.log(`[DEBUG]   Failed to find reply/original author! replyTimestamp=${replyTimestamp}, originalAuthor=${originalAuthor}`)
            }
          } else {
            if (DEBUG_REPLIES) console.log(`[DEBUG]   Begin Reference regex did not match!`)
          }
          continue
        }

        // Check for preview header: "Content... by AuthorName"
        // Next line should be the same AuthorName, then timestamp
        if (isPreviewHeader(trimmed) && isValidAuthor(nextLine) && timestampRegex.test(lineAfterNext)) {
          // This is a preview header - skip it, we'll get content from the actual message
          state = "found_preview"
          continue
        }

        // Check for direct author + timestamp (no preview header)
        if (isValidAuthor(trimmed) && timestampRegex.test(nextLine)) {
          // Save previous message if exists
          if (currentAuthor && currentTimestamp && (currentContent.length > 0 || currentReactions.length > 0)) {
            messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
          }

          // Start new message
          currentAuthor = trimmed
          currentTimestamp = nextLine
          currentContent = []
          currentReactions = []
          currentAttachments = []
          if (!isReply) {
            replyTo = undefined
          }
          state = "found_author"
        }
        break

      case "found_preview":
        // Check for Begin Reference first (might be a reply after a preview)
        if (trimmed.startsWith("Begin Reference,")) {
          state = "seeking"
          i-- // Reprocess this line in seeking state
          break
        }

        // After preview header, expect AuthorName + timestamp
        if (isValidAuthor(trimmed) && timestampRegex.test(nextLine)) {
          // Save previous message if exists
          if (currentAuthor && currentTimestamp && (currentContent.length > 0 || currentReactions.length > 0)) {
            messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
          }

          currentAuthor = trimmed
          currentTimestamp = nextLine
          currentContent = []
          currentReactions = []
          currentAttachments = []
          if (!isReply) {
            replyTo = undefined
          }
          state = "found_author"
        } else {
          // Not what we expected, go back to seeking
          state = "seeking"
        }
        break

      case "found_author":
        // Skip the timestamp line
        if (timestampRegex.test(trimmed)) {
          state = "reading_content"
          isReply = false // Reset for next message
        }
        break

      case "reading_content":
        // Check for new message preview header
        if (isPreviewHeader(trimmed) && isValidAuthor(nextLine) && timestampRegex.test(lineAfterNext)) {
          // Save current message
          if (currentContent.length > 0 || currentReactions.length > 0) {
            messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
            currentContent = []
            currentReactions = []
            currentAttachments = []
            isReply = false
            replyTo = undefined
          }
          state = "found_preview"
          break
        }

        // Check for direct author + timestamp (new message without preview)
        if (isValidAuthor(trimmed) && timestampRegex.test(nextLine)) {
          // Save current message
          if (currentContent.length > 0 || currentReactions.length > 0) {
            messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
          }

          currentAuthor = trimmed
          currentTimestamp = nextLine
          currentContent = []
          currentReactions = []
          currentAttachments = []
          isReply = false
          replyTo = undefined
          state = "found_author"
          break
        }

        // Check for reply reference
        if (trimmed.startsWith("Begin Reference,")) {
          if (DEBUG_REPLIES) console.log(`[DEBUG] Line ${i}: Found Begin Reference in reading_content state`)
          // Save current message first
          if (currentContent.length > 0 || currentReactions.length > 0) {
            messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
            currentContent = []
            currentReactions = []
            currentAttachments = []
          }

          const refMatch = trimmed.match(/Begin Reference, (.+) by ([A-Z][a-z]+ [A-Z][a-z ]+)$/)
          if (refMatch) {
            const replyAuthor = refMatch[2].trim()
            const preview = refMatch[1].trim()
            if (DEBUG_REPLIES) console.log(`[DEBUG]   Reply author: ${replyAuthor}, preview: ${preview.substring(0, 30)}...`)

            // Find reply author line and original author line
            let replyTimestamp = ""
            let originalAuthor = ""
            let originalTimestamp = ""
            let originalAuthorLineIndex = -1
            let foundReplyAuthorLine = false

            for (let j = i + 1; j < Math.min(i + 15, lines.length); j++) {
              const scanLine = lines[j]?.trim() || ""
              const scanNextLine = lines[j + 1]?.trim() || ""

              // Find reply author (first author match)
              if (!foundReplyAuthorLine && scanLine === replyAuthor && timestampRegex.test(scanNextLine)) {
                replyTimestamp = scanNextLine
                foundReplyAuthorLine = true
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Found reply timestamp: ${replyTimestamp}`)
                continue
              }

              // Find original author (second author match - can be same person for self-replies)
              if (foundReplyAuthorLine && !originalAuthor && isValidAuthor(scanLine) && timestampRegex.test(scanNextLine)) {
                originalAuthor = scanLine
                originalTimestamp = scanNextLine
                originalAuthorLineIndex = j
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Found original author: ${originalAuthor} at line ${j}`)
                break
              }
            }

            if (replyTimestamp && originalAuthor) {
              if (DEBUG_REPLIES) console.log(`[DEBUG]   Setting up reply: ${replyAuthor} replying to ${originalAuthor}`)
              // Set up the reply message
              currentAuthor = replyAuthor
              currentTimestamp = replyTimestamp
              currentContent = []
              currentReactions = []
              currentAttachments = []
              isReply = true
              skipQuotedLines = 0 // Reset quoted line counter
              replyTo = {
                author: originalAuthor,
                timestamp: originalTimestamp,
                preview: preview,
              }

              // Skip ahead past the quoted content
              if (originalAuthorLineIndex > 0) {
                i = originalAuthorLineIndex + 1
                state = "reading_reply_content"
                if (DEBUG_REPLIES) console.log(`[DEBUG]   Transitioning to reading_reply_content, i=${i}`)
              }
            } else {
              if (DEBUG_REPLIES) console.log(`[DEBUG]   Failed to find reply/original author! replyTimestamp=${replyTimestamp}, originalAuthor=${originalAuthor}`)
              state = "seeking"
            }
          } else {
            if (DEBUG_REPLIES) console.log(`[DEBUG]   Begin Reference regex did not match!`)
            state = "seeking"
          }
          break
        }

        // Parse reactions: emoji followed by "N Name reactions."
        if (trimmed.length > 0 && trimmed.length <= 4 && /[^\w\s]/.test(trimmed)) {
          const countMatch = nextLine.match(/^(\d+) ([A-Za-z\s-]+) reactions?\.?$/)
          if (countMatch) {
            currentReactions.push({
              emoji: trimmed,
              name: countMatch[2].trim(),
              count: parseInt(countMatch[1]),
            })
            i += 2 // Skip emoji line, count line, and the bare number line
            continue
          }
        }

        // Skip custom emoji reactions (e.g., "exco_daniel", "blob-dance-emoji")
        if (/^[a-z_-]+$/.test(trimmed) && /^\d+ [a-z_-]+ reactions?\.?$/i.test(nextLine)) {
          i += 2
          continue
        }

        // Skip standalone numbers (reaction count duplicates)
        if (/^\d+$/.test(trimmed)) {
          continue
        }

        // Check for attachments
        if (trimmed.includes("(GIF Image)") || trimmed.startsWith("GIF by") || /GIF\)$/.test(trimmed)) {
          currentAttachments.push({ type: "gif", description: trimmed })
          continue
        }
        if (trimmed.startsWith("Url Preview for")) {
          currentAttachments.push({
            type: "link",
            description: trimmed.replace("Url Preview for ", ""),
          })
          continue
        }
        if (trimmed.startsWith("www.") || trimmed.startsWith("http")) {
          currentAttachments.push({ type: "link", description: trimmed })
          continue
        }
        if (trimmed.includes("Praise card sent") || trimmed === "Praise") {
          currentAttachments.push({ type: "praise", description: trimmed })
          continue
        }

        // Skip UI elements
        if (
          trimmed === "Last read" ||
          trimmed === "has context menu" ||
          trimmed === "Jump to newest" ||
          trimmed === "undefined" ||
          trimmed === "Review your praise history" ||
          trimmed === "Send praise"
        ) {
          continue
        }

        // Skip single reaction line format: "1 Name reaction."
        if (/^\d+ [A-Za-z\s-]+ reactions?\.?$/.test(trimmed)) {
          continue
        }

        // Add to content (but not empty lines)
        if (trimmed) {
          currentContent.push(trimmed)
        }
        break

      case "reading_reply_content":
        // In this state, we're inside a reply block after the original author's timestamp
        // The structure is: QuotedContent (often ending with …) then ActualReplyContent
        // We skip the quoted content and capture everything after the ellipsis line
        if (DEBUG_REPLIES) console.log(`[DEBUG] Line ${i} reading_reply_content: "${trimmed.substring(0, 50)}" (content.len=${currentContent.length}, skipQuoted=${skipQuotedLines})`)

        // Check for new message (ends the reply)
        if (isPreviewHeader(trimmed) && isValidAuthor(nextLine) && timestampRegex.test(lineAfterNext)) {
          if (DEBUG_REPLIES) console.log(`[DEBUG]   -> New preview header, saving reply: ${currentAuthor} with ${currentContent.length} content lines`)
          messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
          currentContent = []
          currentReactions = []
          currentAttachments = []
          isReply = false
          replyTo = undefined
          state = "found_preview"
          break
        }

        // Check for new Begin Reference (another reply)
        if (trimmed.startsWith("Begin Reference,")) {
          if (DEBUG_REPLIES) console.log(`[DEBUG]   -> New Begin Reference, saving reply: ${currentAuthor} with ${currentContent.length} content lines, isReply=${isReply}`)
          messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
          currentContent = []
          currentReactions = []
          currentAttachments = []
          isReply = false
          replyTo = undefined
          state = "seeking"
          i--
          break
        }

        // Check for direct author + timestamp
        if (isValidAuthor(trimmed) && timestampRegex.test(nextLine)) {
          if (DEBUG_REPLIES) console.log(`[DEBUG]   -> New author ${trimmed}, saving reply: ${currentAuthor} with ${currentContent.length} content lines`)
          messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))

          currentAuthor = trimmed
          currentTimestamp = nextLine
          currentContent = []
          currentReactions = []
          currentAttachments = []
          isReply = false
          replyTo = undefined
          state = "found_author"
          break
        }

        // Parse reactions
        if (trimmed.length > 0 && trimmed.length <= 4 && /[^\w\s]/.test(trimmed)) {
          const countMatch = nextLine.match(/^(\d+) ([A-Za-z\s-]+) reactions?\.?$/)
          if (countMatch) {
            currentReactions.push({
              emoji: trimmed,
              name: countMatch[2].trim(),
              count: parseInt(countMatch[1]),
            })
            i += 2
            continue
          }
        }

        // Skip custom emoji reactions
        if (/^[a-z_-]+$/.test(trimmed) && /^\d+ [a-z_-]+ reactions?\.?$/i.test(nextLine)) {
          i += 2
          continue
        }

        // Skip standalone numbers
        if (/^\d+$/.test(trimmed)) {
          continue
        }

        // Skip single reaction line format
        if (/^\d+ [A-Za-z\s-]+ reactions?\.?$/.test(trimmed)) {
          continue
        }

        // Skip UI elements
        if (
          trimmed === "Last read" ||
          trimmed === "has context menu" ||
          trimmed === "Jump to newest" ||
          trimmed === "undefined"
        ) {
          continue
        }

        // Quoted content in Teams replies often ends with "…" (ellipsis)
        // If we see a line ending with ellipsis, that's the end of quoted content
        // The next non-empty line is the actual reply
        if (trimmed.endsWith("…") || trimmed.endsWith("...")) {
          // This is the last line of quoted content - skip it
          // The next lines will be the actual reply
          if (DEBUG_REPLIES) console.log(`[DEBUG]   Skipping ellipsis line`)
          continue
        }

        // Check if this line looks like it's part of the original quoted message
        // The first line after the original author's timestamp is the quoted content
        // It should roughly match the start of the preview text
        if (replyTo && currentContent.length === 0 && skipQuotedLines === 0) {
          // First non-empty line after original author timestamp - this is quoted content
          // Check if it looks like it could be the start of the original message (matches preview)
          const previewStart = replyTo.preview.replace(/…$/, "").replace(/\.\.\.$/, "").trim()
          // Check if this line is similar to the start of the preview (quoted message)
          if (trimmed.startsWith(previewStart.substring(0, Math.min(10, previewStart.length))) ||
              previewStart.startsWith(trimmed.substring(0, Math.min(10, trimmed.length)))) {
            if (DEBUG_REPLIES) console.log(`[DEBUG]   Skipping quoted content (matches preview)`)
            skipQuotedLines = 1
            continue
          }
        }

        // Add to reply content
        if (trimmed) {
          if (DEBUG_REPLIES) console.log(`[DEBUG]   Adding reply content: "${trimmed.substring(0, 40)}"`)
          currentContent.push(trimmed)
        }
        break
    }
  }

  // Don't forget the last message
  if (currentAuthor && currentTimestamp && (currentContent.length > 0 || currentReactions.length > 0)) {
    messages.push(createMessage(currentAuthor, currentTimestamp, currentContent, currentReactions, currentAttachments, isReply, replyTo))
  }

  // Calculate date range
  const dates = messages.map((m) => parseDate(m.timestamp)).filter((d) => d !== null) as Date[]

  return {
    channel,
    scrapedAt: new Date().toISOString(),
    messageCount: messages.length,
    dateRange: {
      earliest: dates.length > 0 ? new Date(Math.min(...dates.map((d) => d.getTime()))).toISOString().split("T")[0] : "",
      latest: dates.length > 0 ? new Date(Math.max(...dates.map((d) => d.getTime()))).toISOString().split("T")[0] : "",
    },
    messages,
  }
}

function createMessage(
  author: string,
  timestamp: string,
  content: string[],
  reactions: Reaction[],
  attachments: Attachment[],
  isReply: boolean,
  replyTo?: TeamsMessage["replyTo"]
): TeamsMessage {
  const [datePart] = timestamp.split(" ")
  const timePart = timestamp.replace(datePart + " ", "")
  const contentText = content.join("\n").trim()

  return {
    id: generateMessageId(author, timestamp),
    author,
    timestamp,
    date: datePart,
    time: timePart,
    content: contentText,
    isReply,
    replyTo,
    reactions,
    attachments,
    mentions: extractMentions(contentText),
  }
}

// Main execution
async function main() {
  const { values } = parseArgs({
    args: Bun.argv.slice(2),
    options: {
      channel: { type: "string", short: "c" },
      output: { type: "string", short: "o", default: "./teams-messages.json" },
      raw: { type: "string", short: "r" },
      help: { type: "boolean", short: "h" },
    },
    strict: true,
  })

  if (values.help) {
    console.log(`
Microsoft Teams Chat Scraper

Usage:
  bun teams-scraper.ts [options]

Options:
  -c, --channel <name>   Expected channel name (for validation)
  -o, --output <path>    Output JSON file path (default: ./teams-messages.json)
  -r, --raw <path>       Use raw text file instead of clipboard capture
  -h, --help             Show this help message

Examples:
  bun teams-scraper.ts
  bun teams-scraper.ts -o ./engineers-chat.json
  bun teams-scraper.ts -r ./clipboard-dump.txt -o ./parsed.json
`)
    return
  }

  let rawContent: string

  if (values.raw) {
    console.log(`📄 Reading from file: ${values.raw}`)
    rawContent = await Bun.file(values.raw).text()
  } else {
    rawContent = await captureTeamsContent()
  }

  console.log(`📊 Captured ${rawContent.length} characters`)

  // Parse the content
  console.log("🔍 Parsing messages...")
  const data = parseTeamsStateMachine(rawContent)

  console.log(`✅ Parsed ${data.messageCount} messages`)
  console.log(`📅 Date range: ${data.dateRange.earliest} to ${data.dateRange.latest}`)
  console.log(`📢 Channel: ${data.channel}`)

  // Write output
  const outputPath = values.output || "./teams-messages.json"
  await Bun.write(outputPath, JSON.stringify(data, null, 2))
  console.log(`💾 Saved to: ${outputPath}`)

  // Print sample
  if (data.messages.length > 0) {
    console.log("\n📝 Sample messages:")
    for (const msg of data.messages.slice(0, 3)) {
      console.log(`  [${msg.timestamp}] ${msg.author}: ${msg.content.substring(0, 60)}...`)
      if (msg.reactions.length > 0) {
        console.log(`    Reactions: ${msg.reactions.map((r) => `${r.emoji || r.name}(${r.count})`).join(", ")}`)
      }
    }
  }
}

main().catch(console.error)
