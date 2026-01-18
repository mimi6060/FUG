# FUG Project - Git Flow Strategy

## Branch Structure

```
master (production)
  │
  └── develop (integration)
        │
        ├── feature/XXX (new features)
        ├── bugfix/XXX (bug fixes)
        ├── release/X.Y.Z (release preparation)
        └── hotfix/XXX (production fixes)
```

## Main Branches

### `master`
- **Purpose**: Production-ready code
- **Protected**: Yes (requires PR + review)
- **Deploy**: Automatically deployed to production
- **Rule**: Never commit directly

### `develop`
- **Purpose**: Integration branch for features
- **Protected**: Yes (requires PR)
- **Deploy**: Automatically deployed to staging
- **Rule**: All features merge here first

## Supporting Branches

### Feature Branches
- **Naming**: `feature/<ticket-id>-<short-description>`
- **Branch from**: `develop`
- **Merge to**: `develop`
- **Examples**:
  - `feature/FUG-001-user-authentication`
  - `feature/FUG-012-event-creation`

```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/FUG-XXX-description

# Work on feature...
git add .
git commit -m "feat: description"

# Finish feature
git checkout develop
git pull origin develop
git merge --no-ff feature/FUG-XXX-description
git push origin develop
git branch -d feature/FUG-XXX-description
```

### Bugfix Branches
- **Naming**: `bugfix/<ticket-id>-<short-description>`
- **Branch from**: `develop`
- **Merge to**: `develop`
- **Examples**:
  - `bugfix/FUG-045-login-validation`
  - `bugfix/FUG-067-map-zoom`

### Release Branches
- **Naming**: `release/<version>`
- **Branch from**: `develop`
- **Merge to**: `master` AND `develop`
- **Examples**:
  - `release/1.0.0`
  - `release/1.1.0`

```bash
# Create release branch
git checkout develop
git checkout -b release/1.0.0

# Bump version, fix bugs...
git commit -m "chore: bump version to 1.0.0"

# Finish release
git checkout master
git merge --no-ff release/1.0.0
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin master --tags

git checkout develop
git merge --no-ff release/1.0.0
git push origin develop

git branch -d release/1.0.0
```

### Hotfix Branches
- **Naming**: `hotfix/<version>-<description>`
- **Branch from**: `master`
- **Merge to**: `master` AND `develop`
- **Examples**:
  - `hotfix/1.0.1-critical-auth-fix`

```bash
# Create hotfix branch
git checkout master
git checkout -b hotfix/1.0.1-critical-fix

# Fix the issue...
git commit -m "fix: critical issue"

# Finish hotfix
git checkout master
git merge --no-ff hotfix/1.0.1-critical-fix
git tag -a v1.0.1 -m "Hotfix 1.0.1"
git push origin master --tags

git checkout develop
git merge --no-ff hotfix/1.0.1-critical-fix
git push origin develop

git branch -d hotfix/1.0.1-critical-fix
```

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or correcting tests
- `chore`: Build process, dependencies, etc.
- `ci`: CI/CD configuration

### Scopes
- `auth`: Authentication
- `events`: Events feature
- `profile`: User profile
- `social`: Social features (follow, etc.)
- `map`: Map functionality
- `gamification`: Points/achievements
- `infra`: Infrastructure/DevOps
- `api`: API/Functions

### Examples
```
feat(events): add event creation form
fix(auth): resolve login validation error
docs(readme): update installation instructions
refactor(profile): extract avatar component
chore(deps): update Flutter dependencies
ci(github): add release workflow
```

## Workflow Summary

1. **New Feature**
   ```
   develop → feature/XXX → develop
   ```

2. **Bug Fix (non-critical)**
   ```
   develop → bugfix/XXX → develop
   ```

3. **Release**
   ```
   develop → release/X.Y.Z → master + develop
   ```

4. **Hotfix (critical production issue)**
   ```
   master → hotfix/X.Y.Z → master + develop
   ```

## Git Aliases (Recommended)

Add to your `~/.gitconfig`:

```ini
[alias]
    # Feature workflow
    feature-start = "!f() { git checkout develop && git pull && git checkout -b feature/$1; }; f"
    feature-finish = "!f() { git checkout develop && git pull && git merge --no-ff feature/$1 && git branch -d feature/$1; }; f"

    # Bugfix workflow
    bugfix-start = "!f() { git checkout develop && git pull && git checkout -b bugfix/$1; }; f"
    bugfix-finish = "!f() { git checkout develop && git pull && git merge --no-ff bugfix/$1 && git branch -d bugfix/$1; }; f"

    # Useful shortcuts
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate
```

## Protection Rules (GitHub)

Configure these rules for `master` and `develop`:

### Master Branch
- [x] Require pull request reviews (2 approvals)
- [x] Require status checks to pass
- [x] Require branches to be up to date
- [x] Include administrators
- [x] Restrict who can push (maintainers only)

### Develop Branch
- [x] Require pull request reviews (1 approval)
- [x] Require status checks to pass
- [x] Require branches to be up to date

## Current Status

- [x] `master` branch created
- [x] `develop` branch created
- [ ] GitHub repository created
- [ ] Branch protection rules configured
- [ ] CI/CD pipelines connected
