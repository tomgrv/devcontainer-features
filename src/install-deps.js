// @format
/**
 * install-deps.js
 * Resolves devcontainer feature dependencies using BFS topological sort (Kahn's algorithm).
 * Reads devcontainer-feature.json files and returns an ordered install list.
 */
import { readFileSync, existsSync } from 'fs'
import { join } from 'path'

/**
 * Read and parse a devcontainer-feature.json for a given feature directory.
 * @param {string} featureDir - absolute path to feature directory
 * @returns {object|null} parsed manifest or null if not found/invalid
 */
export function readManifest(featureDir) {
    const manifestPath = join(featureDir, 'devcontainer-feature.json')
    if (!existsSync(manifestPath)) return null
    try {
        return JSON.parse(readFileSync(manifestPath, 'utf8'))
    } catch {
        return null
    }
}

/**
 * Extract a local feature id from a ghcr.io reference key.
 * e.g. "ghcr.io/tomgrv/devcontainer-features/common-utils:5" -> "common-utils"
 * @param {string} key
 * @returns {string|null}
 */
export function parseFeatureId(key) {
    const match = key.match(/tomgrv\/devcontainer-features\/([^:/]+)/)
    return match ? match[1] : null
}

/**
 * Build a dependency graph for the given list of features.
 * Each feature maps to a Set of local features it must be installed after.
 * @param {string} srcDir - path to src directory containing feature folders
 * @param {string[]} features - feature names to process
 * @returns {Map<string, Set<string>>} map of feature -> set of its local deps
 */
export function buildDepGraph(srcDir, features) {
    const featureSet = new Set(features)
    const graph = new Map()
    for (const feature of features) {
        const manifest = readManifest(join(srcDir, feature))
        const deps = new Set()
        if (manifest) {
            for (const key of Object.keys(manifest.dependsOn || {})) {
                const dep = parseFeatureId(key)
                if (dep && featureSet.has(dep)) deps.add(dep)
            }
            for (const key of manifest.installsAfter || []) {
                const dep = parseFeatureId(key)
                if (dep && featureSet.has(dep)) deps.add(dep)
            }
        }
        graph.set(feature, deps)
    }
    return graph
}

/**
 * Topological sort using Kahn's BFS algorithm.
 * @param {Map<string, Set<string>>} graph - adjacency map (node -> deps it must follow)
 * @returns {string[]} sorted feature names (dependencies first)
 * @throws {Error} if a cycle is detected
 */
export function topoSort(graph) {
    const inDegree = new Map([...graph.keys()].map((k) => [k, 0]))
    const adj = new Map([...graph.keys()].map((k) => [k, []]))

    for (const [node, deps] of graph) {
        for (const dep of deps) {
            if (adj.has(dep)) adj.get(dep).push(node)
            inDegree.set(node, (inDegree.get(node) || 0) + 1)
        }
    }

    const queue = [...inDegree.entries()]
        .filter(([, d]) => d === 0)
        .map(([k]) => k)
    const sorted = []

    while (queue.length) {
        const node = queue.shift()
        sorted.push(node)
        for (const neighbor of adj.get(node) || []) {
            inDegree.set(neighbor, inDegree.get(neighbor) - 1)
            if (inDegree.get(neighbor) === 0) queue.push(neighbor)
        }
    }

    if (sorted.length !== graph.size) {
        throw new Error('Circular dependency detected among features')
    }
    return sorted
}

/**
 * Sort a given list of features in dependency order without expanding transitive deps.
 * Only dependencies that are also in the `requested` list are considered for ordering.
 *
 * @param {string} srcDir   - path to src directory
 * @param {string[]} requested - feature names to sort
 * @returns {string[]} same features in dependency-first order
 */
export function resolveDeps(srcDir, requested) {
    const graph = buildDepGraph(srcDir, requested)
    return topoSort(graph)
}

/**
 * Expand a requested feature list to include all transitive local dependencies,
 * then return the full set topologically sorted (dependencies first).
 * Only local features (those with a devcontainer-feature.json in srcDir) are included.
 *
 * @param {string} srcDir   - path to src directory
 * @param {string[]} requested - seed feature names
 * @returns {string[]} expanded + sorted list
 */
export function expandAndSort(srcDir, requested) {
    const all = new Set(requested)
    let changed = true
    while (changed) {
        changed = false
        for (const feature of [...all]) {
            const manifest = readManifest(join(srcDir, feature))
            if (!manifest) continue
            for (const key of Object.keys(manifest.dependsOn || {})) {
                const dep = parseFeatureId(key)
                if (dep && !all.has(dep) && existsSync(join(srcDir, dep))) {
                    all.add(dep)
                    changed = true
                }
            }
        }
    }
    const graph = buildDepGraph(srcDir, [...all])
    return topoSort(graph)
}
