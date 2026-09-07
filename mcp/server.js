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

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')
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

const transport = new StdioServerTransport()
await server.connect(transport)
