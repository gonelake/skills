# Adapter Development Guide

## How to Add a New Tool Adapter

Adding support for a new AI tool takes three steps (down from five after the
Registry refactor):

1. Declare the tool id in `src/core/types.ts`.
2. Implement an **Extractor** and an **Importer**.
3. Register the factories in `src/registry/defaults.ts`.

There is no CLI `switch` to touch and no detector config table to keep in
sync — detection is driven by declarative config on the Extractor itself.

---

## Step 1: Add Tool ID

In `src/core/types.ts`:

```typescript
export const TOOL_IDS = [
  'codebuddy', 'openclaw', 'hermes', 'claude-code', 'cursor',
  'chatgpt', 'doubao', 'kimi',
  'my-tool', // ← add here
] as const;

export const TOOL_NAMES: Record<ToolId, string> = {
  // ...
  'my-tool': 'My Tool',
};
```

`isToolId(value)` is auto-updated by TypeScript inference.

---

## Step 2a: Create Extractor (local / file-based tool)

Create `src/extractors/<tool-id>.ts`. The `BaseExtractor` provides:

- default `detect()` that reads your declarative `detectConfig`
- `readFileSafe(path)` — reads a file with the `MAX_READ_SIZE` (10MB) guard
- `dirExists(path)` — true only for directories, false on error
- `createEmptyData(workspace?)` — blank `MemoBridgeData` skeleton
- `createMeta(method, workspace, total, categories, earliest?, latest?)` — meta builder

```typescript
import { BaseExtractor, type DetectConfig } from './base.js';
import { scanAndRedact } from '../core/privacy.js';
import type { ExtractOptions, MemoBridgeData } from '../core/types.js';

export default class MyToolExtractor extends BaseExtractor {
  readonly toolId = 'my-tool' as const;

  // Declarative detection. The base class's detect() uses this to check
  // `~/` global paths and, if a workspacePath is passed, the listed markers
  // under that workspace.
  readonly detectConfig: DetectConfig = {
    globalPaths: ['~/.my-tool'],
    workspaceMarkers: ['.my-tool', '.my-tool.yaml'],
    description: 'My Tool with its memory files',
  };

  async extract(options: ExtractOptions): Promise<MemoBridgeData> {
    const root = options.workspace ?? /* default root */;
    const data = this.createEmptyData(root);

    const content = await this.readFileSafe(join(root, 'memory.md'));
    if (content) {
      const { redacted_content } = scanAndRedact(content);
      // Parse redacted_content and populate data.profile/knowledge/projects/etc.
    }

    // Optional: put tool-specific structured data in extensions.
    // data.extensions ??= {};
    // data.extensions['my-tool'] = { skills: [...] };

    data.meta = this.createMeta('file', root, countTotal(data), countCategories(data));
    return data;
  }
}
```

**Important:** If the tool's global directory is hardcoded (like
`~/.claude` or `~/.cursor`), expose it via a `protected getGlobalDir()`
override so tests can redirect it to a tmp path:

```typescript
protected getGlobalDir(): string {
  return join(homedir(), '.my-tool');
}
```

## Step 2b: Create Extractor (cloud / prompt-guided tool)

For tools without local files (like ChatGPT, Doubao, Kimi), extend
`CloudExtractor` instead of `BaseExtractor`:

```typescript
import { CloudExtractor } from './cloud.js';

export default class MyCloudExtractor extends CloudExtractor {
  readonly toolId = 'my-cloud' as const;
}
```

`CloudExtractor` provides:
- `detect()` that always returns `detected: true` with a hint to use the
  `prompt` command.
- `extract()` that throws `ExtractionNotSupportedError` with a friendly
  message pointing users to `memo-bridge prompt --for <toolId>`.

You may override either method if the tool exposes an API later.

---

## Step 3: Create Importer

Create `src/importers/<tool-id>.ts`. Use `readExistingFile` from
`./base.js` when implementing append-mode writes — it distinguishes
missing files (ENOENT → treat as empty) from real errors (permissions,
EISDIR, etc.) that should surface rather than silently corrupt output.

```typescript
import { writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { BaseImporter, readExistingFile } from './base.js';
import { validateWritePath, validateContentSize, isNotSymlink } from '../utils/security.js';
import type { MemoBridgeData, ImportOptions, ImportResult } from '../core/types.js';

export default class MyToolImporter extends BaseImporter {
  readonly toolId = 'my-tool' as const;

  async import(data: MemoBridgeData, options: ImportOptions): Promise<ImportResult> {
    if (!options.workspace) {
      return {
        success: false, method: 'file_write',
        items_imported: 0, items_skipped: 0,
        instructions: 'Please pass --workspace for this tool.',
      };
    }

    const targetPath = validateWritePath(join(options.workspace, 'MEMORY.md'));
    const content = this.buildContent(data);
    validateContentSize(content);

    if (options.dryRun) {
      return {
        success: true, method: 'file_write',
        items_imported: this.countImported(data), items_skipped: 0,
        output_path: targetPath,
        instructions: `[DRY RUN] ${options.overwrite ? 'overwrite' : 'append'}: ${targetPath}`,
      };
    }

    if (!await isNotSymlink(targetPath)) {
      throw new Error(`Refusing to write: ${targetPath} is a symlink`);
    }

    if (options.overwrite) {
      await writeFile(targetPath, content, 'utf-8');
    } else {
      const existing = await readExistingFile(targetPath);
      await writeFile(targetPath, existing + '\n' + content, 'utf-8');
    }

    return {
      success: true, method: 'file_write',
      items_imported: this.countImported(data), items_skipped: 0,
      output_path: targetPath,
    };
  }

  private buildContent(data: MemoBridgeData): string {
    // Build tool-specific format from MemoBridgeData
    // ...
  }
}
```

For instruction-based import (ChatGPT / Doubao / Kimi style), look at
`src/importers/instruction-based.ts` for the pattern: `method: 'instruction'`
with a `clipboard_content` string and user-facing `instructions`.

---

## Step 4: Register in defaults

In `src/registry/defaults.ts`, add one line each for the extractor and
importer:

```typescript
extractorRegistry.register('my-tool',  () => new MyToolExtractor());
importerRegistry.register('my-tool',   () => new MyToolImporter());
```

That's it — the CLI picks it up automatically. No `switch` edits, no
detector config updates.

---

## Step 5: Add Tests

Follow the conventions in `tests/extractors/*.test.ts` and
`tests/importers/*.test.ts`:

- Use `mkdtemp` to build a hermetic fixture tree under `os.tmpdir()`.
- For extractors whose global dir is hardcoded, subclass in the test file
  to override `getGlobalDir()` — this keeps tests from reading the user's
  real home directory.
- Assert on concrete data shapes (not just `toBeTruthy`).
- Add a privacy-integration test that feeds a fake token through the
  extractor and asserts it's redacted in the output.

---

## Security Checklist

- [ ] All write paths go through `validateWritePath()`
- [ ] Content size checked with `validateContentSize()`
- [ ] Symlink check with `isNotSymlink()` before every `writeFile()`
- [ ] Privacy scan with `scanAndRedact()` on every extracted text blob
- [ ] `readExistingFile()` used (not raw `readFile().catch()`) for append mode
- [ ] File reads use `this.readFileSafe(path)` so the 10MB limit applies
- [ ] `--dry-run` supported and has its own test case
- [ ] No `as ToolId` casts on external input — use `isToolId(value)` guard

---

## Where to Put Tool-Specific Data

If your extractor produces data that doesn't fit into the common sections
(profile, knowledge, projects, feeds, raw_memories), put it into
`data.extensions['<tool-id>']` rather than stuffing it into `raw_memories`.
Extensions are tool-namespaced so different tools never collide, and they
round-trip through `memo-bridge.md` as a fenced YAML block.

Example (Hermes's auto-generated skills):

```typescript
data.extensions ??= {};
data.extensions.hermes = { ...data.extensions.hermes, skills: ['a', 'b'] };
```

Importers ignore unknown extensions by default — that's the right behavior
for cross-tool migration since tool-specific data rarely translates.
