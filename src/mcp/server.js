#!/usr/bin/env node
/** @format */

// MCP server that teaches an agent how to use this repo to set up another
// repo's dev environment: which features exist, and the exact commands to
// install all of them (or one) into a target project.
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const SRC = join(ROOT, 'src')

function listFeatures() {
    return readdirSync(SRC, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
        .filter((name) =>
            existsSync(join(SRC, name, 'devcontainer-feature.json'))
        )
        .map((name) => {
            const meta = JSON.parse(
                readFileSync(
                    join(SRC, name, 'devcontainer-feature.json'),
                    'utf8'
                )
            )
            return { id: meta.id ?? name, description: meta.description ?? '' }
        })
}

function featureReadme(feature) {
    const path = join(SRC, feature, 'README.md')
    if (!existsSync(path)) throw new Error(`Unknown feature: ${feature}`)
    return readFileSync(path, 'utf8')
}

function setupCommand({ feature, method }) {
    const target = feature ? `add ${feature}` : 'add -a'
    if (method === 'npm') {
        return `npx tomgrv/devcontainer-features -- ${target}`
    }
    return `curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- ${target}`
}

// Heuristics mapping a signal file in the target repo to the feature it suggests.
const SIGNALS = [
    {
        path: 'composer.json',
        feature: 'larasets',
        reason: 'PHP/Composer project',
    },
    { path: '.git', feature: 'gitutils', reason: 'Git repository' },
    { path: '.git', feature: 'githooks', reason: 'Git repository' },
    {
        path: 'package.json',
        feature: 'gitversion',
        reason: 'npm project (semver releases)',
    },
    {
        path: '.github/workflows',
        feature: 'act',
        reason: 'GitHub Actions workflows to run locally',
    },
    {
        path: '.devcontainer',
        feature: 'gateway',
        reason: 'devcontainer present (corporate SSL gateways commonly needed)',
    },
]

function inspectTargetRepo(targetDir) {
    if (!existsSync(targetDir))
        throw new Error(`No such directory: ${targetDir}`)
    const recommended = SIGNALS.filter((s) =>
        existsSync(join(targetDir, s.path))
    )
    const seen = new Set()
    return recommended
        .filter((s) =>
            seen.has(s.feature) ? false : (seen.add(s.feature), true)
        )
        .map(({ feature, reason }) => ({ feature, reason }))
}

// Read-only preview of what configure-feature would do to a target repo:
// which stub files are new vs. would merge into an existing file. Mirrors
// _configure-feature.sh's two rename rules (see that script for the source
// of truth): a plain stub's basename collapses ".." to "." (e.g.
// "..gitignore" -> ".gitignore"), while a root-level "_<qualifier>.package.json"
// or "_<qualifier>.composer.json" fragment merges into the top-level
// package.json/composer.json instead of deploying under its own name.
function previewFeature(feature, targetDir) {
    const stubsDir = join(SRC, feature, 'stubs')
    if (!existsSync(stubsDir))
        throw new Error(`Feature has no stubs: ${feature}`)
    if (!existsSync(targetDir))
        throw new Error(`No such directory: ${targetDir}`)

    const files = []
    const walk = (dir, depth) => {
        for (const entry of readdirSync(dir, { withFileTypes: true })) {
            const abs = join(dir, entry.name)
            if (entry.isDirectory()) {
                walk(abs, depth + 1)
                continue
            }
            const rel = abs.slice(stubsDir.length + 1)
            const dir_ = dirname(rel)
            const base = entry.name
            const rootFragmentMatch =
                depth === 0 && /^_.*\.(package|composer)\.json$/.test(base)
            const targetRel = rootFragmentMatch
                ? base.replace(/^_.*\.(package|composer)\.json$/, '$1.json')
                : join(dir_, base.replace(/\.\./g, '.'))
            files.push({
                stub: rel,
                target: targetRel,
                action: rootFragmentMatch
                    ? 'merge-into-json'
                    : existsSync(join(targetDir, targetRel))
                      ? 'merge'
                      : 'create',
            })
        }
    }
    walk(stubsDir, 0)
    return files
}

const server = new McpServer({
    name: 'devcontainer-features',
    version: '1.0.0',
})

server.registerTool(
    'list_features',
    {
        title: 'List devcontainer features',
        description:
            'List every feature this repo can install into a target repo/dev environment, with a short description of each.',
        inputSchema: {},
    },
    async () => ({
        content: [
            { type: 'text', text: JSON.stringify(listFeatures(), null, 2) },
        ],
    })
)

server.registerTool(
    'get_feature_readme',
    {
        title: 'Get feature README',
        description:
            "Fetch a feature's full README (usage, config options, stub files it deploys) so an agent can decide whether/how to use it.",
        inputSchema: {
            feature: z.string().describe('Feature id, e.g. "githooks"'),
        },
    },
    async ({ feature }) => ({
        content: [{ type: 'text', text: featureReadme(feature) }],
    })
)

server.registerTool(
    'get_setup_command',
    {
        title: 'Get setup command for a target repo',
        description:
            "Return the exact shell command to run inside a target repo to install every feature (default) or one named feature, so an agent can bootstrap that repo's dev environment.",
        inputSchema: {
            feature: z
                .string()
                .optional()
                .describe(
                    'Feature id to install; omit to install all features'
                ),
            method: z
                .enum(['npm', 'curl'])
                .optional()
                .describe(
                    'npm requires Node.js on the target machine; curl needs neither. Defaults to curl.'
                ),
        },
    },
    async ({ feature, method }) => ({
        content: [{ type: 'text', text: setupCommand({ feature, method }) }],
    })
)

server.registerTool(
    'inspect_target_repo',
    {
        title: 'Inspect target repo and recommend features',
        description:
            'Look at signal files in a target repo (composer.json, .git, .github/workflows, ...) and recommend which features from this repo fit, so an agent does not have to guess.',
        inputSchema: {
            targetDir: z
                .string()
                .describe('Absolute path to the target repo on disk'),
        },
    },
    async ({ targetDir }) => ({
        content: [
            {
                type: 'text',
                text: JSON.stringify(inspectTargetRepo(targetDir), null, 2),
            },
        ],
    })
)

server.registerTool(
    'preview_feature_install',
    {
        title: 'Dry-run a feature install',
        description:
            'List the stub files a feature would deploy into a target repo, and whether each would be created new or merged into a file that already exists there — without writing anything.',
        inputSchema: {
            feature: z.string().describe('Feature id, e.g. "githooks"'),
            targetDir: z
                .string()
                .describe('Absolute path to the target repo on disk'),
        },
    },
    async ({ feature, targetDir }) => ({
        content: [
            {
                type: 'text',
                text: JSON.stringify(
                    previewFeature(feature, targetDir),
                    null,
                    2
                ),
            },
        ],
    })
)

const transport = new StdioServerTransport()
await server.connect(transport)
