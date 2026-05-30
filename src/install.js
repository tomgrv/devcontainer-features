#!/usr/bin/env node
// @format
/**
 * install.js - Devcontainer features cross-platform installer
 *
 * Replaces the shell-based install.sh as the npm bin entry so that the package
 * can be used on all platforms (Linux, macOS, Windows).
 *
 * Usage:
 *   devcontainer-features [options] [-- feature...]
 *
 * Options:
 *   -a, --all       Install all default features (reads stubs/.devcontainer/devcontainer.json)
 *   -u, --upd       Update all features (reads .devcontainer/devcontainer.json in cwd)
 *   -s, --stubs     Install/update project stubs only
 *   -p, --package   Path to a package.json to read feature list from
 *   -h, --help      Show this help message
 */
import {
    existsSync,
    readFileSync,
    readdirSync,
    statSync,
    symlinkSync,
    chmodSync,
    unlinkSync,
} from 'fs'
import { join, resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import { spawnSync } from 'child_process'
import { resolveDeps } from './install-deps.js'
import {
    isWindows,
    isContainer,
    installFeat,
    deployStubs,
} from './install-feat.js'

// ---------------------------------------------------------------------------
// Resolve paths
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
/** Directory that contains feature sub-directories (this file lives here). */
const srcDir = __dirname
/** Repository/package root (parent of src/). */
const rootDir = resolve(__dirname, '..')
/** Path to the shared configure-feature script. */
const configureScript = join(srcDir, 'common-utils', '_configure-feature.sh')
/** Path to the common-utils directory. */
const commonUtilsDir = join(srcDir, 'common-utils')

// ---------------------------------------------------------------------------
// Common-utils environment setup (mirrors install.sh symlink lifecycle)
// ---------------------------------------------------------------------------

/**
 * Create symlinks in common-utils/ for each _*.sh file (strips leading _
 * and .sh extension), make them executable, and add the directory to PATH.
 * Returns a cleanup function that removes the created symlinks.
 *
 * This matches the symlink lifecycle in the original install.sh and lets
 * shell scripts invoke utilities like `zz_colors`, `zz_log`, etc. by name.
 *
 * @returns {() => void} cleanup function
 */
function setupCommonUtils() {
    if (isWindows || !existsSync(commonUtilsDir)) return () => {}

    const created = []

    for (const file of readdirSync(commonUtilsDir)) {
        if (!file.startsWith('_') || !file.endsWith('.sh')) continue
        const scriptPath = join(commonUtilsDir, file)

        // Ensure the script is executable
        try {
            chmodSync(scriptPath, 0o755)
        } catch {
            // ignore permission errors (e.g. read-only filesystem)
        }

        // Create symlink without leading _ and without .sh extension
        const linkName = file.replace(/^_/, '').replace(/\.sh$/, '')
        const linkPath = join(commonUtilsDir, linkName)
        if (!existsSync(linkPath)) {
            try {
                symlinkSync(scriptPath, linkPath)
                created.push(linkPath)
            } catch {
                // ignore if symlink already exists or cannot be created
            }
        }
    }

    // Prepend common-utils to PATH so scripts can find utilities by name
    process.env.PATH = `${commonUtilsDir}${process.platform === 'win32' ? ';' : ':'}${process.env.PATH}`

    return () => {
        for (const link of created) {
            try {
                unlinkSync(link)
            } catch {
                // ignore
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Argument Parsing
// ---------------------------------------------------------------------------

function printHelp() {
    console.log(`
Usage: devcontainer-features [options] [-- feature...]

Options:
  -a, --all       Install all default features
  -u, --upd       Update all features from .devcontainer/devcontainer.json
  -s, --stubs     Install/update project stubs only
  -p, --package   Path to a package.json to read feature list from
  -h, --help      Show this help message

Examples:
  devcontainer-features -h
  devcontainer-features -s
  devcontainer-features -a
  devcontainer-features -- gitutils githooks
  devcontainer-features -p package.json -- gitutils
`)
}

/**
 * Parse process.argv into a structured options object.
 * @returns {{ all: boolean, upd: boolean, stubs: boolean, package: string|null, features: string[] }}
 */
function parseArgs() {
    const opts = {
        all: false,
        upd: false,
        stubs: false,
        package: null,
        features: [],
    }

    const argv = process.argv.slice(2)
    let afterDashDash = false

    for (let i = 0; i < argv.length; i++) {
        const arg = argv[i]
        if (arg === '--') {
            afterDashDash = true
            continue
        }
        if (afterDashDash) {
            opts.features.push(arg)
            continue
        }
        switch (arg) {
            case '-a':
            case '--all':
                opts.all = true
                break
            case '-u':
            case '--upd':
                opts.upd = true
                break
            case '-s':
            case '--stubs':
                opts.stubs = true
                break
            case '-p':
            case '--package':
                opts.package = argv[++i]
                break
            case '-h':
            case '--help':
                printHelp()
                process.exit(0)
                break
            default:
                if (!arg.startsWith('-')) opts.features.push(arg)
        }
    }

    return opts
}

// ---------------------------------------------------------------------------
// Feature-list helpers
// ---------------------------------------------------------------------------

/**
 * Strip JSON single-line comments (// ...) before parsing.
 * @param {string} text
 * @returns {string}
 */
function stripJsonComments(text) {
    return text.replace(/^\s*\/\/.*$/gm, '')
}

/**
 * Read a JSON file, stripping single-line comments.
 * @param {string} filePath
 * @returns {object}
 */
function readJson(filePath) {
    const raw = readFileSync(filePath, 'utf8')
    return JSON.parse(stripJsonComments(raw))
}

/**
 * Extract local feature names from a devcontainer.json features map.
 * @param {object} featuresMap - { "ghcr.io/tomgrv/devcontainer-features/gitutils": {} }
 * @returns {string[]}
 */
function extractFeaturesFromDevcontainer(featuresMap) {
    return Object.keys(featuresMap || {})
        .filter((k) => k.includes('tomgrv/devcontainer-features'))
        .map((k) => k.split('/').pop().split(':')[0])
        .filter(Boolean)
}

/**
 * Return all feature names available in srcDir (directories with devcontainer-feature.json).
 * @returns {string[]}
 */
function allAvailableFeatures() {
    return readdirSync(srcDir).filter((name) => {
        const featureDir = join(srcDir, name)
        return (
            statSync(featureDir).isDirectory() &&
            existsSync(join(featureDir, 'devcontainer-feature.json'))
        )
    })
}

// ---------------------------------------------------------------------------
// Stubs installer (configures common-utils stubs into cwd)
// ---------------------------------------------------------------------------

function installStubs() {
    if (isWindows) {
        console.log(
            '[stubs] Stub installation is not supported on Windows natively.'
        )
        return
    }
    console.log('[stubs] Installing stubs from common-utils...')
    const result = spawnSync('sh', [configureScript, '-s', rootDir, '.'], {
        stdio: 'inherit',
        env: process.env,
        cwd: process.cwd(),
    })
    if (result.status !== 0) {
        console.error('[stubs] Stub installation failed')
        process.exit(result.status ?? 1)
    }
    console.log('[stubs] Stubs installed')
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
    const opts = parseArgs()

    // Set up common-utils symlinks + PATH, capture cleanup for later
    const cleanupEnv = setupCommonUtils()

    try {
        // Resolve feature list from various sources
        let features = [...opts.features]

        if (opts.all) {
            opts.stubs = true
            const dcJson = join(
                rootDir,
                'stubs',
                '.devcontainer',
                'devcontainer.json'
            )
            if (existsSync(dcJson)) {
                const dc = readJson(dcJson)
                features = extractFeaturesFromDevcontainer(dc.features)
            } else {
                features = allAvailableFeatures()
            }
        }

        if (opts.upd) {
            opts.stubs = true
            const dcJson = join(
                process.cwd(),
                '.devcontainer',
                'devcontainer.json'
            )
            if (existsSync(dcJson)) {
                const dc = readJson(dcJson)
                features = extractFeaturesFromDevcontainer(dc.features)
            } else {
                console.error(
                    '[upd] .devcontainer/devcontainer.json not found in cwd'
                )
                process.exit(1)
            }
        }

        if (opts.package) {
            if (!existsSync(opts.package)) {
                console.error(`[package] File not found: ${opts.package}`)
                process.exit(1)
            }
            const pkg = readJson(opts.package)
            if (features.length === 0) {
                features = extractFeaturesFromDevcontainer(
                    pkg?.devcontainer?.features || {}
                )
            }
        }

        console.log('[install] Installing devcontainer/features')

        // Install stubs if requested
        if (opts.stubs) {
            installStubs()
        }

        if (features.length === 0) {
            if (!opts.stubs) printHelp()
            return
        }

        console.log(`[install] Selected features: ${features.join(', ')}`)

        // Resolve dependency order
        let ordered
        try {
            ordered = resolveDeps(srcDir, features)
        } catch (err) {
            console.error(`[deps] ${err.message}`)
            process.exit(1)
        }

        if (!isContainer) {
            // --- Local environment: install features natively ---
            for (const feature of ordered) {
                try {
                    installFeat(srcDir, feature, configureScript)
                } catch (err) {
                    console.error(`[install] ${err.message}`)
                    process.exit(1)
                }
            }
        } else if (opts.stubs) {
            // --- Inside container with stubs: deploy feature stubs ---
            for (const feature of ordered) {
                try {
                    deployStubs(join(srcDir, feature), feature, configureScript)
                } catch (err) {
                    console.error(`[stubs] ${err.message}`)
                    process.exit(1)
                }
            }
        } else {
            // --- Inside container without stubs: show devcontainer instructions ---
            console.log(
                'You are in a container — use these as devcontainer features:'
            )
            for (const feature of ordered) {
                console.log(
                    `  ghcr.io/tomgrv/devcontainer-features/${feature}`
                )
            }
        }
    } finally {
        // Always remove symlinks created during setup
        cleanupEnv()
    }
}

main().catch((err) => {
    console.error(err.message)
    process.exit(1)
})
