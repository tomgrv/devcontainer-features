<!-- @format -->

# Changelog

## v5.26.0 (2025-10-01)

_Commits from: v5.25.0..HEAD_

### 📂 Unscoped changes

#### Features

- ✨ add VERSION file update with gitversion semver on checkout (#11) ([1d08e6e](https://github.com/tomgrv/devcontainer-features/commit/1d08e6e4b1cb56bf106e9bab6aadc5610fc3b2fb))
- ✨ update package.json to make them installable ([96e663e](https://github.com/tomgrv/devcontainer-features/commit/96e663e8c802db491bda593c76b90fbc2f09d686))

#### Other changes

- Add comprehensive GitHub Copilot instructions for devcontainer-features repository (#9) ([c3d40be](https://github.com/tomgrv/devcontainer-features/commit/c3d40be614546e9e27e37ec2ef83458fa120f9c5))
- Add validate-pr.yml workflow to larasets feature stubs (#21) ([1c6ba09](https://github.com/tomgrv/devcontainer-features/commit/1c6ba0973262ac49b610b4f187e74ffdf023c00d))
- Add validate-pr.yml workflow to larasets feature stubs (#21) ([bde381e](https://github.com/tomgrv/devcontainer-features/commit/bde381e7de5a0c3f3474cfd85fa7443385889dd4))
- Correct filename reference from \_zz_logs.sh to \_zz_log.sh in install.sh (#17) ([594243b](https://github.com/tomgrv/devcontainer-features/commit/594243baef47d36eb35f59f7095f928b4eea73b2))
- 📦️ ensure package.json are there ([ec38ffc](https://github.com/tomgrv/devcontainer-features/commit/ec38ffc234aaa48e0133a41025b26c51f9904dce))

### 📦 common-utils changes

#### Bug Fixes

- 🐛 improve argument handling and usage output formatting ([3aa56d4](https://github.com/tomgrv/devcontainer-features/commit/3aa56d410c3d19c5ec41c0b55f2ff1975eafc1de))

#### Features

- ✨ add dispatcher utility script ([38dfce8](https://github.com/tomgrv/devcontainer-features/commit/38dfce894a5f2603f16ba17574fee1a8374bcc50))
- ✨ add zz_input util ([3c2cc9c](https://github.com/tomgrv/devcontainer-features/commit/3c2cc9cb1700e0e8a604dc068f0b858eb3edc1e4))

#### Other changes

- ♻️ rename zz_utility to zz_dispatch ([4ceb267](https://github.com/tomgrv/devcontainer-features/commit/4ceb26734f3af4db1dbf57c561a4d73282d2a852))

### 📦 githooks changes

#### Features

- ✨ add checkout version util ([d10c373](https://github.com/tomgrv/devcontainer-features/commit/d10c3737c5893362098b63ba37b4a78d584ee14e))
- ✨ add sync-versions script and PR title validation workflow ([4e8a48d](https://github.com/tomgrv/devcontainer-features/commit/4e8a48de53ff643a8c159d4926b8572d1244777b))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 add bumped files commit ([d944af2](https://github.com/tomgrv/devcontainer-features/commit/d944af2ba50f50e3a26c0edfe48e5fee065a8afe))
- 🐛 ensure lock file presence ([97ee738](https://github.com/tomgrv/devcontainer-features/commit/97ee7386c232724913cb4cde894f875e7f541374))

#### Features

- ✨ add auto rebase script and enhance commit deletion logic ([971090e](https://github.com/tomgrv/devcontainer-features/commit/971090e6c04ffed8e4f1770f3dfed493b5b01889))
- ✨ add clear command ([f038e51](https://github.com/tomgrv/devcontainer-features/commit/f038e51f54b5eed6c820262d2e7b7dd0083de193))
- ✨ add git pn alias for push --no-verify (#13) ([ceb1fbe](https://github.com/tomgrv/devcontainer-features/commit/ceb1fbe38e3f739f2b1812c433a3c023386ea649))
- ✨ add scripts for squash merging and production releases ([e9b103a](https://github.com/tomgrv/devcontainer-features/commit/e9b103a7822a843f045cd4ea6a80b7891aa0711e))
- ✨ add scripts for squash merging and production releases ([fa52dec](https://github.com/tomgrv/devcontainer-features/commit/fa52dec3de4dfabd28347869aef9dfc99e8cb416))
- ✨ migrate to gitversion utils ([426b923](https://github.com/tomgrv/devcontainer-features/commit/426b9233a515e61c964532709485f4177745f021))

#### Other changes

- ♻️ ✨ add scripts to fix author and edit last commit ([8780a2b](https://github.com/tomgrv/devcontainer-features/commit/8780a2b8c5baf68e0f30f10ffdd334da883ffeb7))
- ♻️ move to zz_log ([b0bf13b](https://github.com/tomgrv/devcontainer-features/commit/b0bf13bedc981b62bf1931a5624b648987fd4c51))

### 📦 gitversion changes

#### Bug Fixes

- 🐛 improve version handling ([bdd74fc](https://github.com/tomgrv/devcontainer-features/commit/bdd74fc69e87a3a6d291a7d2184ce1821f9d6820))

#### Features

- ✨ add bump utilities ([8819028](https://github.com/tomgrv/devcontainer-features/commit/88190286546b1eefc42add9a8f0f73b0c7dbc49c))
- ✨ enhance tag creation logic with force option handling ([193baf8](https://github.com/tomgrv/devcontainer-features/commit/193baf84f12e0daa0e99698501af0e817bea29b5))

### 📦 larasets changes

#### Bug Fixes

- 🐛 refine vendor directory exclusions for modules and packages ([e814109](https://github.com/tomgrv/devcontainer-features/commit/e814109816a70b744dbe05ce6ec8eff0b9ee9298))

#### Features

- ✨ update task labels and commands ([9456163](https://github.com/tomgrv/devcontainer-features/commit/9456163b5662c6b3f3d9c7abd0ff3d51a5060e8a))

## 1.1.0 (2024-06-22)

### Features

- ✨ add githook ([ab4c1fc](https://github.com/tomgrv/devcontainer-features/commit/ab4c1fc5eb4f712ed2009baf9a3cadb11097c7b5))
- add features ([4b26d9d](https://github.com/tomgrv/devcontainer-features/commit/4b26d9d876caffb15078a6baaabf76d1a2707e6f))

---

_Generated on 2025-10-01 by [tomgrv/devcontainer-features](https://github.com/tomgrv/devcontainer-features)_
