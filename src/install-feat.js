// @format
/**
 * install-feat.js
 * Installs a single devcontainer feature.
 *
 * On Unix/Linux (container or local): runs the feature's install.sh and configure scripts.
 * On Windows or inside a running container: shows instructions for devcontainer use.
 */
import { existsSync } from 'fs'
import { join } from 'path'
import { spawnSync } from 'child_process'

/** True when running on Windows. */
export const isWindows = process.platform === 'win32'

/** True when running inside a devcontainer, Codespace, or Remote Container. */
export const isContainer =
    process.env.CODESPACES === 'true' ||
    process.env.REMOTE_CONTAINERS === 'true' ||
    Boolean(process.env.DEV_CONTAINER_FILE_PATH)

/**
 * Run a shell script via `sh` with optional extra arguments.
 * @param {string} script - absolute path to the shell script
 * @param {string[]} [args] - additional arguments
 * @returns {{ success: boolean, exitCode: number }}
 */
export function runScript(script, args = []) {
    if (!existsSync(script)) {
        throw new Error(`Script not found: ${script}`)
    }
    const result = spawnSync('sh', [script, ...args], {
        stdio: 'inherit',
        env: process.env,
    })
    return { success: result.status === 0, exitCode: result.status ?? 1 }
}

/**
 * Configure a feature by running the common-utils configure-feature script.
 * Merges stubs and package.json templates from the feature source into the
 * current working directory.
 *
 * @param {string} configureScript - path to `_configure-feature.sh`
 * @param {string} featureSrcDir   - source directory passed with -s
 * @param {string} featureName     - feature name (id)
 * @returns {{ success: boolean, exitCode: number }}
 */
export function configureFeature(configureScript, featureSrcDir, featureName) {
    if (isWindows) {
        console.log(
            `[configure] Skipping ${featureName} configuration (not supported on Windows)`
        )
        return { success: true, skipped: true }
    }
    const result = spawnSync(
        'sh',
        [configureScript, '-s', featureSrcDir, featureName],
        { stdio: 'inherit', env: process.env }
    )
    return { success: result.status === 0, exitCode: result.status ?? 1 }
}

/**
 * Determine the feature installation target directory.
 * Returns the first of `/usr/local/share/<feature>` or `/tmp/<feature>` that
 * exists after a successful install, or null if neither is found.
 * @param {string} featureName
 * @returns {string|null}
 */
export function findInstallTarget(featureName) {
    const candidates = [
        `/usr/local/share/${featureName}`,
        `/tmp/${featureName}`,
    ]
    for (const dir of candidates) {
        if (existsSync(dir)) return dir
    }
    return null
}

/**
 * Install a single feature locally (outside a container).
 * Runs `src/<feature>/install.sh` and then configures the feature in the cwd.
 *
 * @param {string} srcDir          - path to the src directory (contains feature folders)
 * @param {string} featureName     - feature id to install
 * @param {string} configureScript - absolute path to `_configure-feature.sh`
 * @throws {Error} if the feature or its install.sh is not found, or if installation fails
 */
export function installFeat(srcDir, featureName, configureScript) {
    const featureDir = join(srcDir, featureName)

    if (!existsSync(featureDir)) {
        throw new Error(
            `Feature '${featureName}' not found (looked in ${featureDir})`
        )
    }

    if (isWindows) {
        console.log(
            `[install] Feature installation is not supported on Windows natively.`
        )
        console.log(
            `[install] Use as a devcontainer feature: ghcr.io/tomgrv/devcontainer-features/${featureName}`
        )
        return { success: true, skipped: true }
    }

    const installScript = join(featureDir, 'install.sh')
    if (!existsSync(installScript)) {
        throw new Error(
            `install.sh not found for feature '${featureName}' in ${featureDir}`
        )
    }

    console.log(`[install] Running ${featureName}/install.sh...`)
    const installResult = runScript(installScript)
    if (!installResult.success) {
        throw new Error(
            `Installation failed for '${featureName}' (exit code ${installResult.exitCode})`
        )
    }
    console.log(`[install] ${featureName} installed successfully`)

    const target = findInstallTarget(featureName)
    if (target) {
        console.log(`[configure] Configuring ${featureName} from ${target}...`)
        const configResult = configureFeature(configureScript, target, featureName)
        if (!configResult.success) {
            throw new Error(
                `Configuration failed for '${featureName}' (exit code ${configResult.exitCode})`
            )
        }
        console.log(`[configure] ${featureName} configured`)
    } else {
        console.log(
            `[configure] No install target found for '${featureName}', skipping configure`
        )
    }

    return { success: true }
}

/**
 * Deploy stubs for a feature into the current working directory.
 * Used when inside a container and stubs mode is active.
 *
 * @param {string} featureSrcDir   - feature source directory (stubs source)
 * @param {string} featureName     - feature id
 * @param {string} configureScript - absolute path to `_configure-feature.sh`
 */
export function deployStubs(featureSrcDir, featureName, configureScript) {
    if (isWindows) {
        console.log(
            `[stubs] Skipping stub deployment for ${featureName} (not supported on Windows)`
        )
        return { success: true, skipped: true }
    }
    console.log(`[stubs] Deploying stubs for ${featureName}...`)
    const result = configureFeature(configureScript, featureSrcDir, featureName)
    if (!result.success) {
        throw new Error(
            `Stub deployment failed for '${featureName}' (exit code ${result.exitCode})`
        )
    }
    console.log(`[stubs] ${featureName} stubs deployed`)
    return { success: true }
}
