# justfile - Build automation for i18n-node-enhanced
# Requires: just (https://github.com/casey/just)
# Install: cargo install just

# Show available recipes
default:
    @just --list

# Development workflows
# ======================

# Install dependencies
install:
    npm install

# Run tests
test:
    npm test

# Run tests with coverage
test-coverage:
    npm run coverage

# Run linter
lint:
    npx eslint i18n.js index.js test/

# Fix linting issues
lint-fix:
    npx eslint --fix i18n.js index.js test/

# Format code
format:
    npx prettier --write "**/*.{js,json,md}"

# Validate locale files
validate-locales:
    node tools/validate-locales.js

# Check for missing translations
check-translations:
    node tools/missing-translations.js

# Clean build artifacts
clean:
    rm -rf node_modules coverage .nyc_output
    rm -rf examples/*/node_modules
    rm -rf bindings/rescript/lib
    rm -rf wasm/target wasm/pkg

# Full clean including compiled binaries
clean-all: clean
    rm -rf wasm/pkg/*.wasm
    find . -name "*.log" -delete

# Build workflows
# ================

# Build WASM core
build-wasm:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "wasm" ]; then
        cd wasm
        cargo build --release --target wasm32-unknown-unknown
        wasm-pack build --target nodejs --out-dir pkg
        echo "✅ WASM core built successfully"
    else
        echo "⚠️  WASM directory not found, skipping"
    fi

# Build ReScript bindings
build-rescript:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "bindings/rescript" ]; then
        cd bindings/rescript
        npm install
        npx rescript build
        echo "✅ ReScript bindings built successfully"
    else
        echo "⚠️  ReScript bindings not found, skipping"
    fi

# Build Deno module (validation only, no compilation needed)
build-deno:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "deno" ]; then
        cd deno
        deno check mod.ts
        echo "✅ Deno module validated successfully"
    else
        echo "⚠️  Deno directory not found, skipping"
    fi

# Build all polyglot components
build-all: build-wasm build-rescript build-deno
    @echo "✅ All components built successfully"

# Example workflows
# ==================

# Run Express example
example-express:
    cd examples/express4-cookie && npm install && npm start

# Run NestJS example
example-nestjs:
    cd examples/nestjs && npm install && npm run dev

# Run Hono example
example-hono:
    cd examples/hono && npm install && npm run dev

# Run all examples (test mode)
example-all:
    @echo "Testing all examples..."
    @for dir in examples/*/; do \
        if [ -f "$$dir/package.json" ]; then \
            echo "Testing $$dir"; \
            cd "$$dir" && npm install && npm test && cd ../..; \
        fi \
    done

# Quality assurance
# ==================

# Run all QA checks
qa: lint test validate-locales
    @echo "✅ All QA checks passed"

# Pre-commit checks
pre-commit: lint-fix format test
    @echo "✅ Pre-commit checks passed"

# Pre-release checks
pre-release: clean install build-all test-coverage validate-locales
    @echo "✅ Pre-release checks passed"

# Security workflows
# ===================

# Run npm audit
audit:
    npm audit --audit-level=moderate

# Fix npm vulnerabilities
audit-fix:
    npm audit fix

# Check for outdated dependencies
outdated:
    npm outdated

# Update dependencies
update:
    npm update

# RSR Compliance
# ===============

# Check RSR compliance
rsr-check:
    @echo "🔍 Checking RSR compliance..."
    @echo ""
    @echo "📋 Documentation:"
    @test -f README.md && echo "  ✅ README.md" || echo "  ❌ README.md"
    @test -f LICENSE && echo "  ✅ LICENSE" || echo "  ❌ LICENSE"
    @test -f SECURITY.md && echo "  ✅ SECURITY.md" || echo "  ❌ SECURITY.md"
    @test -f CONTRIBUTING.md && echo "  ✅ CONTRIBUTING.md" || echo "  ❌ CONTRIBUTING.md"
    @test -f CODE_OF_CONDUCT.md && echo "  ✅ CODE_OF_CONDUCT.md" || echo "  ❌ CODE_OF_CONDUCT.md"
    @test -f MAINTAINERS.md && echo "  ✅ MAINTAINERS.md" || echo "  ❌ MAINTAINERS.md"
    @test -f CHANGELOG.md && echo "  ✅ CHANGELOG.md" || echo "  ❌ CHANGELOG.md"
    @echo ""
    @echo "🌐 .well-known/:"
    @test -f .well-known/security.txt && echo "  ✅ security.txt" || echo "  ❌ security.txt"
    @test -f .well-known/ai.txt && echo "  ✅ ai.txt" || echo "  ❌ ai.txt"
    @test -f .well-known/humans.txt && echo "  ✅ humans.txt" || echo "  ❌ humans.txt"
    @echo ""
    @echo "🔧 Build system:"
    @test -f justfile && echo "  ✅ justfile" || echo "  ❌ justfile"
    @test -f package.json && echo "  ✅ package.json" || echo "  ❌ package.json"
    @test -f .gitignore && echo "  ✅ .gitignore" || echo "  ❌ .gitignore"
    @echo ""
    @echo "🔒 Security:"
    @grep -q "SECURITY.md" README.md && echo "  ✅ Security policy linked" || echo "  ⚠️  Security policy not linked in README"
    @echo ""
    @echo "🧪 Testing:"
    @test -d test && echo "  ✅ test/ directory" || echo "  ❌ test/ directory"
    @npm test > /dev/null 2>&1 && echo "  ✅ Tests pass" || echo "  ❌ Tests fail"
    @echo ""
    @echo "📦 Polyglot bindings:"
    @test -d bindings/rescript && echo "  ✅ ReScript bindings" || echo "  ⚠️  ReScript bindings"
    @test -d deno && echo "  ✅ Deno module" || echo "  ⚠️  Deno module"
    @test -d wasm && echo "  ✅ WASM core" || echo "  ⚠️  WASM core"
    @echo ""
    @echo "🏢 Enterprise features:"
    @test -d adapters && echo "  ✅ Enterprise adapters" || echo "  ⚠️  Enterprise adapters"
    @test -f audit/forensics.js && echo "  ✅ Audit system" || echo "  ⚠️  Audit system"
    @test -f automation/api.js && echo "  ✅ Automation API" || echo "  ⚠️  Automation API"
    @echo ""
    @echo "📊 Current RSR Level: Bronze (working toward Silver)"
    @echo "🔐 TPCF Perimeter: 3 (Community Sandbox)"

# Generate RSR compliance report
rsr-report:
    @just rsr-check > rsr-compliance-report.txt
    @echo "✅ RSR compliance report generated: rsr-compliance-report.txt"

# Documentation
# ==============

# Generate API documentation
docs:
    npx jsdoc -c jsdoc.json

# Serve documentation locally
docs-serve: docs
    npx http-server ./docs -p 8080

# Release workflows
# ==================

# Bump version (patch)
bump-patch:
    npm version patch

# Bump version (minor)
bump-minor:
    npm version minor

# Bump version (major)
bump-major:
    npm version major

# Publish to npm (requires auth)
publish:
    npm publish

# Create GitHub release
release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    git tag -a "v{{VERSION}}" -m "Release {{VERSION}}"
    git push origin "v{{VERSION}}"
    echo "✅ Release v{{VERSION}} tagged and pushed"

# Nix workflows (planned)
# ========================

# Build with Nix (requires flake.nix)
nix-build:
    @echo "⚠️  Nix build not yet implemented"
    @echo "Planned: nix build"

# Enter Nix development shell
nix-shell:
    @echo "⚠️  Nix shell not yet implemented"
    @echo "Planned: nix develop"

# CI/CD simulation
# =================

# Simulate CI pipeline
ci: install lint test validate-locales audit
    @echo "✅ CI pipeline simulation passed"

# Simulate full CI/CD
ci-full: clean install build-all test-coverage validate-locales audit rsr-check
    @echo "✅ Full CI/CD simulation passed"

# Performance
# ============

# Run benchmarks
benchmark:
    @test -f benchmarks/performance.js && node benchmarks/performance.js || echo "⚠️  No benchmarks found"

# Profile memory usage
profile-memory:
    node --expose-gc --trace-gc i18n.js

# Utilities
# ==========

# Show project statistics
stats:
    @echo "📊 Project Statistics"
    @echo ""
    @echo "📁 Files:"
    @find . -name "*.js" -not -path "./node_modules/*" -not -path "./coverage/*" | wc -l | xargs echo "  JavaScript files:"
    @find . -name "*.md" -not -path "./node_modules/*" | wc -l | xargs echo "  Markdown files:"
    @echo ""
    @echo "📏 Lines of code:"
    @find . -name "*.js" -not -path "./node_modules/*" -not -path "./coverage/*" -exec wc -l {} + | tail -1
    @echo ""
    @echo "🧪 Tests:"
    @grep -r "describe\\|it(" test/ | wc -l | xargs echo "  Test cases:"
    @echo ""
    @echo "🌍 Locales:"
    @find locales -name "*.json" 2>/dev/null | wc -l | xargs echo "  Locale files:" || echo "  Locale files: 0"

# Show git status
status:
    git status

# Show recent commits
commits:
    git log --oneline --graph -10

# Offline-first verification
# ============================

# Verify offline functionality
verify-offline:
    @echo "🔌 Verifying offline-first capabilities..."
    @echo ""
    @echo "📦 Static catalog test:"
    @node -e "const {I18n} = require('./index.js'); const i18n = new I18n({staticCatalog: {en: {hello: 'Hello'}}, updateFiles: false}); console.log('  ✅', i18n.__('hello'));"
    @echo ""
    @echo "🚫 Network dependency check:"
    @! grep -r "http://" --include="*.js" --exclude-dir=node_modules --exclude-dir=test . && echo "  ✅ No HTTP dependencies in core" || echo "  ⚠️  HTTP dependencies found"
    @! grep -r "https://" --include="*.js" --exclude-dir=node_modules --exclude-dir=test . && echo "  ✅ No HTTPS dependencies in core" || echo "  ⚠️  HTTPS dependencies found"
    @echo ""
    @echo "💾 File I/O isolation:"
    @echo "  ✅ Can run with updateFiles: false (tested above)"

# Help and information
# ======================

# Show environment information
info:
    @echo "🔧 Environment Information"
    @echo ""
    @echo "Node.js: $(node --version)"
    @echo "npm: $(npm --version)"
    @command -v cargo && echo "Rust: $(cargo --version)" || echo "Rust: not installed"
    @command -v deno && echo "Deno: $(deno --version | head -1)" || echo "Deno: not installed"
    @command -v just && echo "Just: $(just --version)" || echo "Just: installed"
    @echo ""
    @echo "📁 Project: i18n-node-enhanced"
    @echo "📦 Version: $(node -p "require('./package.json').version")"

# Quick start guide
quickstart:
    @echo "🚀 Quick Start Guide"
    @echo ""
    @echo "1. Install dependencies:"
    @echo "   just install"
    @echo ""
    @echo "2. Run tests:"
    @echo "   just test"
    @echo ""
    @echo "3. Check RSR compliance:"
    @echo "   just rsr-check"
    @echo ""
    @echo "4. Run example:"
    @echo "   just example-express"
    @echo ""
    @echo "For full list of commands:"
    @echo "   just --list"
