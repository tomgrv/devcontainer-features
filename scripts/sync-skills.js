#!/usr/bin/env node
/* sync-skills: install skills from ai-coding.json via npx skills */

import { readFileSync } from 'fs'
import { execSync } from 'child_process'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dir = dirname(fileURLToPath(import.meta.url))
const configPath = resolve(__dir, '../ai-coding.json')

try {
  const config = JSON.parse(readFileSync(configPath, 'utf8'))
  const skills = config.skills || []
  const agents = config.agents || []

  if (!skills.length) {
    console.log('sync-skills: no skills in ai-coding.json, skipping')
    process.exit(0)
  }

  if (!agents.length) {
    console.log('sync-skills: no agents in ai-coding.json, skipping')
    process.exit(0)
  }

  const agentArgs = agents.map(a => `-a ${a}`).join(' ')

  for (const skill of skills) {
    const name = typeof skill === 'string' ? skill : skill.name
    const url = typeof skill === 'string'
      ? `tomgrv/devcontainer-features/.agents/skills/${name}`
      : skill.url

    try {
      console.log(`sync-skills: installing ${name}...`)
      execSync(
        `npx --yes skills add -y "${url}" --skills '*' ${agentArgs}`,
        { stdio: 'pipe' }
      )
    } catch (err) {
      console.warn(`sync-skills: failed to install ${name}, continuing...`)
    }
  }

  console.log(`sync-skills: synced ${skills.length} skill(s)`)
} catch (err) {
  if (err.code === 'ENOENT') {
    console.log('sync-skills: ai-coding.json not found, skipping')
  } else {
    console.error('sync-skills: error reading config', err.message)
  }
  process.exit(0)
}
