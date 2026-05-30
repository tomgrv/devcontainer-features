#!/usr/bin/env node
// @format
/**
 * build.js - Build script: copies devcontainer features from src/ to dist/
 *
 * Only directories that contain a devcontainer-feature.json are copied.
 * node_modules directories are excluded.
 *
 * Run via: npm run build
 */
import { cpSync, mkdirSync, rmSync, readdirSync, statSync, existsSync } from 'fs'
import { join, resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const srcDir = __dirname
const rootDir = resolve(__dirname, '..')
const distDir = join(rootDir, 'dist')

/**
 * Filter function for cpSync — excludes node_modules.
 * @param {string} src
 * @returns {boolean}
 */
function filterCopy(src) {
    return !src.includes('node_modules')
}

// Clean and recreate dist/
console.log(`[build] Cleaning ${distDir}...`)
rmSync(distDir, { recursive: true, force: true })
mkdirSync(distDir, { recursive: true })

// Copy each feature directory (those containing devcontainer-feature.json)
const entries = readdirSync(srcDir)
let copied = 0

for (const name of entries) {
    const featureDir = join(srcDir, name)
    if (
        !statSync(featureDir).isDirectory() ||
        !existsSync(join(featureDir, 'devcontainer-feature.json'))
    ) {
        continue
    }

    const destDir = join(distDir, name)
    console.log(`[build] Copying ${name} -> dist/${name}`)
    cpSync(featureDir, destDir, { recursive: true, filter: filterCopy })
    copied++
}

console.log(`[build] Done — ${copied} feature(s) written to dist/`)
