<!-- @format -->

# Changelog

## 5.31.1 (2025-10-09)

_Commits from: v5.30.2..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 correct typo in validate-pr-title job name and use standard PR validation action (#32) ([3a15569](https://github.com/tomgrv/devcontainer-features/commit/3a15569b5be5d48c9d990270203bbfa0e6809768))
- 🐛 ensure upstream tracking when pushing CHANGELOG ([d6b68ca](https://github.com/tomgrv/devcontainer-features/commit/d6b68ca981b0dc5df85cfca74e0aea92aa5140db))
- 🐛 update GitVersion command to use default config path if not specified ([6d424be](https://github.com/tomgrv/devcontainer-features/commit/6d424becfc8ce8dee9bb544f41df65b04f80ad42))

#### Features

- ✨ 🆕 add automatic rebase workflow ([f1601b5](https://github.com/tomgrv/devcontainer-features/commit/f1601b59349301824f4d5457ab2b0e74f2dca058))

#### Other changes

- ✨ Add validate-pr-secret workflow with gitleaks-action (#34) ([0d621cb](https://github.com/tomgrv/devcontainer-features/commit/0d621cbc97763bb04173f72ff5a5f7f913e6fffd))
- Merge tag 'v5.30.0' into develop ([4792b33](https://github.com/tomgrv/devcontainer-features/commit/4792b330b10e25cbe81ff4b27c3fda1b889fe88a))
- Merge tag 'v5.30.1' into develop ([05fcd5d](https://github.com/tomgrv/devcontainer-features/commit/05fcd5dd8486bbe27f70b206951160f9484b8d89))
- Merge tag 'v5.30.2' into develop ([f30c1f4](https://github.com/tomgrv/devcontainer-features/commit/f30c1f4f3c105f26b68d09007699c895ecca185d))
- ♻️ 🛠️ rename job and update workflow name for clarity ([1dec739](https://github.com/tomgrv/devcontainer-features/commit/1dec7390e9c5a1ac6ed45926457ade345fdcbc04))
- ⚡️ update extensions ([2f1ef08](https://github.com/tomgrv/devcontainer-features/commit/2f1ef0859a492de9e429257b8eba252e16f4f678))

### 📦 common-utils changes

#### Features

- ✨ add zz*dist script to manage zz*\* utilities distribution (#30) ([c09d9da](https://github.com/tomgrv/devcontainer-features/commit/c09d9da4938c551ad9e712f2531a691819768c98))

### 📦 githooks changes

#### Other changes

- ♻️ remove checkout-version script ([921e944](https://github.com/tomgrv/devcontainer-features/commit/921e9444b4860fbb51582c15a8b913db5949d07c))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 add missing flag to bump-changelog ([e796429](https://github.com/tomgrv/devcontainer-features/commit/e796429b1e1e354857f3d3b8068e2e1e42cf3cc0))
- 🐛 set default branch ([a79d632](https://github.com/tomgrv/devcontainer-features/commit/a79d63283c86a2f9de51a90ee62099bfa5cf02c8))

#### Features

- ✨ add git fix date (#28) ([7de727c](https://github.com/tomgrv/devcontainer-features/commit/7de727cfb39bc8dc1f12a04f9dbcdf12d8fdfdaa))
- ✨ add script to rebase commits from one branch to another ([9d22977](https://github.com/tomgrv/devcontainer-features/commit/9d22977e0be4ef2133e39db113fcfffc5d8b8cbe))

#### Other changes

- 📦️ 🆕 add automatic rebase action for pr via comments ([448bea2](https://github.com/tomgrv/devcontainer-features/commit/448bea2cd5ca8b78fb92449a44d6d2c8a00c29a3))
- ♻️ 🧹 remove confirmation prompt ([720494a](https://github.com/tomgrv/devcontainer-features/commit/720494ace59083d714ffed2e53d6ac3a1fe20659))

### 📦 gitversion changes

#### Bug Fixes

- 🐛 correct minimal flag argument in bump version utility ([5b766b1](https://github.com/tomgrv/devcontainer-features/commit/5b766b1bd95cc84adbd152aa855ad1131d211e11))

#### Features

- ✨ 🆕 add initial .gitignore for Gitversion ([6881ee8](https://github.com/tomgrv/devcontainer-features/commit/6881ee8623a5384a8447a8dc9ba61000297aa799))

## 5.30.2 (2025-10-02)

_Commits from: v5.30.1..HEAD_

### 📦 gitutils changes

#### Bug Fixes

- 🐛 improve error handling ([5ca79f0](https://github.com/tomgrv/devcontainer-features/commit/5ca79f09b8f5ee3dd14181d53b0b4e43beca9d88))
- 🐛 rename script setrights ([b099626](https://github.com/tomgrv/devcontainer-features/commit/b0996265881bafc375748a29aaa24051d05298a9))

## 5.30.1-beta.1 (2025-10-02)

_Commits from: v5.30.0..HEAD_

### 📦 gitutils changes

#### Bug Fixes

- 🐛 enhance hotfix branch creation and rebase handling ([c17a3d2](https://github.com/tomgrv/devcontainer-features/commit/c17a3d2e086ce09d83b2d443b433c5d632a96616))
- 🐛 refine version extraction ([9de255e](https://github.com/tomgrv/devcontainer-features/commit/9de255ed621955a6cdaf3793d563e104cff7e13a))

## 5.30.0-beta.1 (2025-10-02)

_Commits from: v5.29.1..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v5.28.1' into develop ([9249443](https://github.com/tomgrv/devcontainer-features/commit/924944383f11e06b79ea6632f21c6bc4cd783eff))
- Merge tag 'v5.29.1' into develop ([9fb75b6](https://github.com/tomgrv/devcontainer-features/commit/9fb75b61e0ea7396099711fdba5886f488406883))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 update version retrieval ([2e1d1c5](https://github.com/tomgrv/devcontainer-features/commit/2e1d1c56fec50d6a6d9311d6e69d4a62a50caecf))

### 📦 gitversion changes

#### Bug Fixes

- 🐛 correct version determination ([510e87c](https://github.com/tomgrv/devcontainer-features/commit/510e87ca1a4ed527be33fff5e58bd2b6784688b3))

## 5.29.1-beta.1 (2025-10-02)

_Commits from: v5.29.0..HEAD_

### 📦 gitutils changes

#### Bug Fixes

- 🐛 update file permissions and cleanup ([646f1d5](https://github.com/tomgrv/devcontainer-features/commit/646f1d5173177465866dd6095b761b07c8950ef4))

## v5.28.1 (2025-10-01)

_Commits from: v5.28.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 update package.json files across multiple modules ([eed42a5](https://github.com/tomgrv/devcontainer-features/commit/eed42a568d1ac2f2f28f1442d886b806999adc62))

#### Other changes

- Merge tag 'v5.28.0' into develop ([f8d8983](https://github.com/tomgrv/devcontainer-features/commit/f8d8983a6fab253b4369973a8d59534b4e0ef2e5))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 ensure upstream tracking when pushing changes ([c809a32](https://github.com/tomgrv/devcontainer-features/commit/c809a327d1f07c285d0025eed74b594f0d7f166b))

### 📦 gitversion changes

#### Bug Fixes

- 🐛 enhance version bumping logic ([89b8895](https://github.com/tomgrv/devcontainer-features/commit/89b8895cc7b9d51e2fd565a5929e1ca21c8f23a6))

## v5.28.0 (2025-10-01)

_Commits from: v5.27.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 correct variable assignment syntax in argument processing ([ffa8a1e](https://github.com/tomgrv/devcontainer-features/commit/ffa8a1e07e3ad8fdcb49331ea611169868727924))
- 🐛 remove unnecessary color script sourcing ([0119d55](https://github.com/tomgrv/devcontainer-features/commit/0119d551c762d9583f49ab8c6232fd346bbf7eab))

#### Other changes

- Merge tag 'v5.27.0' into develop ([fc52d6e](https://github.com/tomgrv/devcontainer-features/commit/fc52d6e224126451e0d540797f2f5e60e2d5fe25))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 correct install-plugins in commit hooks ([8d55832](https://github.com/tomgrv/devcontainer-features/commit/8d558327a278fc42ead7325b09f057c95383368d))
- 🐛 handle branch checkout failure ([33fe044](https://github.com/tomgrv/devcontainer-features/commit/33fe044477d5a184fb9a9770594cc071b738234a))

#### Features

- ✨ improve emoji fix script ([f28ad39](https://github.com/tomgrv/devcontainer-features/commit/f28ad395e08fa861244722c2baba97055bb2fc8a))

#### Other changes

- ♻️ improve scripts ([633ea81](https://github.com/tomgrv/devcontainer-features/commit/633ea8147bb942eb1c8d6ff01ce444c6f46f0ac6))

### 📦 gitversion changes

#### Bug Fixes

- 🐛 improve version bump logic ([31dcaa3](https://github.com/tomgrv/devcontainer-features/commit/31dcaa3760ec8d09e9f9fdc84637d00f915473da))

## v5.27.0 (2025-10-01)

_Commits from: v5.26.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 update dependencies ([ed2465e](https://github.com/tomgrv/devcontainer-features/commit/ed2465e7570eec12a4847bed00bafa6967746251))

#### Other changes

- Merge tag 'v5.26.0' into develop ([11f0ad3](https://github.com/tomgrv/devcontainer-features/commit/11f0ad30b2eae7e3faca69a3c426800cb887151d))

### 📦 gitutils changes

#### Bug Fixes

- 🐛 improve error handling for version & CHANGELOG commit ([569cb42](https://github.com/tomgrv/devcontainer-features/commit/569cb423e9d10643d902418c9391f907f524f24c))

#### Features

- ✨ list workspace directories and affected workspaces ([6acab47](https://github.com/tomgrv/devcontainer-features/commit/6acab47128b8119dbfad544dc63e5e081d59c479))

### 📦 gitversion changes

#### Other changes

- ♻️ 🛠️ use git workspaces command ([82ac773](https://github.com/tomgrv/devcontainer-features/commit/82ac77387d98f1d9bedf254db2eb334ef0185853))

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

_Generated on 2025-10-09 by [tomgrv/devcontainer-features](https://github.com/tomgrv/devcontainer-features)_
