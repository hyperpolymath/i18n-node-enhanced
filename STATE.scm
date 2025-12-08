;;; STATE.scm --- Project state checkpoint for polyglot-i18n
;;;
;;; Copyright (C) 2025 polyglot-i18n contributors
;;; SPDX-License-Identifier: MIT
;;;
;;; This file preserves project context, decisions, and next actions
;;; across AI conversation sessions. Format follows hyperpolymath/state.scm.
;;;
;;; Usage:
;;;   - Session End: Update completion percentages, export STATE.scm
;;;   - Session Start: Upload STATE.scm, AI reconstructs context
;;;
;;; Code:

(define-module (polyglot-i18n state)
  #:export (state))

;;;
;;; Metadata
;;;

(define metadata
  '((format-version . "1.0.0")
    (project-name . "polyglot-i18n")
    (created . "2025-12-08")
    (last-updated . "2025-12-08")
    (schema . "hyperpolymath/state.scm")))

;;;
;;; User Context
;;;

(define user-context
  '((maintainer . "hyperpolymath")
    (roles . (architect developer release-manager))
    (languages . (scheme rescript rust javascript nickel))
    (preferred-tools . (guix nix just neovim))
    (values . (reproducibility type-safety performance security))
    (communication-style . terse-technical)))

;;;
;;; Session Context
;;;

(define session-context
  '((branch . "claude/create-state-scm-01XaAo5E8reTup5mJaK56Jg1")
    (task . "Create STATE.scm documenting project position and roadmap")
    (working-directory . "/home/user/polyglot-i18n")
    (git-status . clean)))

;;;
;;; Focus
;;;

(define focus
  '((current-project . polyglot-i18n)
    (phase . "v2.0.0-alpha development")
    (target-milestone . "MVP v1 - ReScript-first with WASM core")
    (deadline . #f)  ; No hard deadline
    (blocking-dependencies . ())))

;;;
;;; Current Position Summary
;;;

(define current-position
  '((version . "0.16.0")
    (target-version . "2.0.0-alpha")
    (status . "Migration from legacy JS to ReScript-first architecture")

    (completed-work
     ((guix-infrastructure
       (status . complete)
       (files . ("guix.scm" "channels.scm" "manifest.scm"))
       (packages . (i18n-wasm i18n-rescript i18n-node-enhanced i18n-cli i18n-dev)))

      (wasm-plural-engine
       (status . complete)
       (file . "wasm/src/lib.rs")
       (features . (cldr-plural-rules 40+-locales cardinal-numbers))
       (locales . (en de fr es it pt ru pl cs ar he ja ko zh hi)))

      (rescript-bindings
       (status . complete)
       (file . "bindings/rescript/I18n.res")
       (type . ffi-to-javascript)
       (note . "These are FFI bindings to JS, not pure ReScript implementation"))

      (nickel-configuration
       (status . complete)
       (file . "config/i18n.ncl")
       (features . (type-contracts environment-presets framework-presets)))

      (legacy-javascript
       (status . stable)
       (file . "i18n.js")
       (features . (translation plurals messageformat mustache sprintf
                    fallbacks auto-reload file-sync object-notation)))

      (test-suite
       (status . comprehensive)
       (directory . "test/")
       (count . 30+)
       (framework . mocha)
       (coverage-tool . nyc))))

    (in-progress-work
     ((wasm-integration
       (status . partial)
       (completion . 60%)
       (done . (plural-engine interpolation-helpers))
       (remaining . (js-bridge runtime-detection lazy-loading)))

      (container-support
       (status . partial)
       (completion . 40%)
       (files . ("container/Containerfile" "container/apko.yaml"))
       (remaining . (ci-integration multi-arch-builds signing)))))

    (not-started
     ((pure-rescript-core
       (description . "Migrate i18n.js logic to pure ReScript")
       (blocked-by . #f)
       (priority . high))

      (deno-module
       (description . "Create Deno-native module with WASM integration")
       (target-directory . "deno/")
       (blocked-by . #f)
       (priority . high))

      (cli-implementation
       (description . "Comprehensive CLI per ROADMAP.adoc")
       (commands . (init translate validate sync extract compile
                    serve migrate benchmark config doctor))
       (blocked-by . #f)
       (priority . medium))

      (documentation-site
       (description . "Antora-based documentation site")
       (framework . antora)
       (blocked-by . #f)
       (priority . low))))))

;;;
;;; Project Catalog
;;;

(define project-catalog
  '(;; Core Packages
    (polyglot-i18n
     (status . in-progress)
     (completion . 45%)
     (category . core)
     (phase . v2-alpha)
     (dependencies . ())
     (blockers . ())
     (next-action . "Implement pure ReScript translation core"))

    ;; Sub-components
    (i18n-wasm
     (status . in-progress)
     (completion . 70%)
     (category . performance)
     (phase . v2-alpha)
     (dependencies . (rust wasm-bindgen))
     (blockers . ())
     (next-action . "Add JS bridge and lazy loading"))

    (i18n-rescript
     (status . in-progress)
     (completion . 30%)
     (category . type-safety)
     (phase . v2-alpha)
     (dependencies . (rescript i18n.js))
     (blockers . ())
     (next-action . "Convert FFI bindings to pure implementation"))

    (i18n-deno
     (status . not-started)
     (completion . 0%)
     (category . runtime)
     (phase . v2-alpha)
     (dependencies . (i18n-wasm))
     (blockers . ())
     (next-action . "Create deno/mod.ts entry point"))

    (i18n-cli
     (status . not-started)
     (completion . 0%)
     (category . tooling)
     (phase . v2-beta)
     (dependencies . (polyglot-i18n))
     (blockers . ())
     (next-action . "Implement init command"))

    (i18n-nickel
     (status . complete)
     (completion . 100%)
     (category . configuration)
     (phase . v2-alpha)
     (dependencies . (nickel))
     (blockers . ())
     (next-action . #f))))

;;;
;;; Route to MVP v1
;;;

(define mvp-route
  '((target . "MVP v1 - Production-ready ReScript-first i18n")

    (milestone-1
     (name . "Foundation Complete")
     (status . mostly-complete)
     (completion . 85%)
     (items
      ((guix-channel-infrastructure (done . #t))
       (nix-fallback-layer (done . partial))
       (chainguard-wolfi-container (done . partial)))))

    (milestone-2
     (name . "Language Transformation")
     (status . in-progress)
     (completion . 40%)
     (items
      ((rescript-core-implementation (done . #f))
       (wasm-performance-core (done . mostly))
       (deno-primary-runtime (done . #f)))))

    (milestone-3
     (name . "Configuration & CLI")
     (status . partial)
     (completion . 50%)
     (items
      ((nickel-configuration-system (done . #t))
       (comprehensive-cli (done . #f))
       (man-pages (done . #f)))))

    (milestone-4
     (name . "Testing & Quality")
     (status . partial)
     (completion . 35%)
     (items
      ((unit-tests-rescript (done . #f))
       (wasm-tests (done . partial))
       (integration-tests (done . partial))
       (security-hardening (done . partial)))))

    (milestone-5
     (name . "CI/CD & Infrastructure")
     (status . not-started)
     (completion . 10%)
     (items
      ((github-actions-pipeline (done . partial))
       (release-automation (done . #f))
       (documentation-site (done . #f)))))))

;;;
;;; Known Issues
;;;

(define issues
  '((technical
     ((issue-1
       (title . "WASM module not integrated with JS runtime")
       (severity . medium)
       (description . "Rust WASM plural engine exists but has no JS bridge")
       (affected . ("wasm/src/lib.rs" "i18n.js"))
       (solution . "Create wasm-bridge.js with lazy loading"))

      (issue-2
       (title . "ReScript bindings are FFI-only")
       (severity . high)
       (description . "Current ReScript code wraps JS, not native implementation")
       (affected . ("bindings/rescript/I18n.res"))
       (solution . "Rewrite core logic in pure ReScript"))

      (issue-3
       (title . "No Deno runtime support")
       (severity . medium)
       (description . "deno/ directory is empty despite being in roadmap")
       (affected . ())
       (solution . "Create deno/mod.ts with proper imports"))))

    (process
     ((issue-4
       (title . "Missing contribution guidelines")
       (severity . low)
       (description . "CONTRIBUTING.md not present")
       (solution . "Create contribution docs"))

      (issue-5
       (title . "No semantic versioning automation")
       (severity . low)
       (description . "Manual version bumps in package.json")
       (solution . "Add semantic-release or similar"))))))

;;;
;;; Questions for Maintainer
;;;

(define questions
  '((q1 (priority . high)
        (question . "Should MVP v1 prioritize Deno or Node.js runtime?")
        (context . "Roadmap says 'Deno primary' but ecosystem is Node-heavy")
        (options . (deno-first node-first parallel-development)))

    (q2 (priority . high)
        (question . "Pure ReScript vs ReScript+JS interop for v1?")
        (context . "Full ReScript rewrite is extensive; hybrid approach is faster")
        (options . (pure-rescript hybrid incremental-migration)))

    (q3 (priority . medium)
        (question . "WASM loading strategy preference?")
        (context . "Lazy loading reduces bundle size but adds complexity")
        (options . (lazy-loading eager-loading conditional-loading)))

    (q4 (priority . medium)
        (question . "Target locales for v1 plural rules?")
        (context . "Current WASM has 40+ locales; all needed for MVP?")
        (options . (all-current top-20-languages expandable-plugin)))

    (q5 (priority . low)
        (question . "CLI in ReScript or keep as Node.js?")
        (context . "CLI could be separate package with different tech stack")
        (options . (rescript-cli node-cli rust-cli)))))

;;;
;;; Long-term Roadmap
;;;

(define long-term-roadmap
  '((phase-1-foundation
     (timeline . "Complete")
     (status . 85%)
     (deliverables
      (guix.scm channels.scm manifest.scm flake.nix
       containerfile apko.yaml)))

    (phase-2-language-transformation
     (timeline . "Current focus")
     (status . 40%)
     (deliverables
      (src/core/I18n.res
       src/runtime/Platform.res
       wasm/pkg/*
       deno/mod.ts)))

    (phase-3-configuration-cli
     (timeline . "Next")
     (status . 50%)
     (deliverables
      (config/i18n.ncl
       cli/main.res
       man/man1/*.1)))

    (phase-4-testing-quality
     (timeline . "After CLI")
     (status . 35%)
     (deliverables
      (tests/unit/rescript/*
       tests/wasm/*
       tests/integration/*
       tests/e2e/*)))

    (phase-5-cicd-infrastructure
     (timeline . "Pre-release")
     (status . 10%)
     (deliverables
      (.github/workflows/ci.yml
       .github/workflows/release.yml
       docs/antora.yml)))

    (phase-6-ecosystem-community
     (timeline . "Post v2.0.0")
     (status . 0%)
     (deliverables
      (guix-channel-publication
       deno.land-publication
       npm-publication
       homebrew-tap)))))

;;;
;;; Critical Next Actions
;;;

(define critical-next-actions
  '((action-1
     (priority . 1)
     (description . "Create WASM-JS bridge for plural engine")
     (files . ("src/wasm-bridge.js" "wasm/pkg/"))
     (estimated-effort . medium)
     (deadline . #f))

    (action-2
     (priority . 2)
     (description . "Scaffold Deno module entry point")
     (files . ("deno/mod.ts" "deno/deps.ts" "deno.json"))
     (estimated-effort . small)
     (deadline . #f))

    (action-3
     (priority . 3)
     (description . "Begin ReScript core implementation")
     (files . ("src/core/I18n.res" "src/core/Locale.res" "src/core/Catalog.res"))
     (estimated-effort . large)
     (deadline . #f))

    (action-4
     (priority . 4)
     (description . "Add WASM build to CI pipeline")
     (files . (".github/workflows/ci.yml"))
     (estimated-effort . small)
     (deadline . #f))

    (action-5
     (priority . 5)
     (description . "Implement CLI init command")
     (files . ("cli/main.js" "cli/commands/init.js"))
     (estimated-effort . medium)
     (deadline . #f))))

;;;
;;; History / Velocity Tracking
;;;

(define history
  '((snapshot-2025-12-08
     (event . "STATE.scm created")
     (milestones-completed . (guix-infrastructure nickel-config wasm-plural-engine))
     (overall-completion . 45%)
     (notes . "Initial state capture for AI session continuity"))))

;;;
;;; Architecture Decisions
;;;

(define architecture-decisions
  '((adr-001
     (title . "Guix channels as primary package source")
     (status . accepted)
     (date . "2024")
     (context . "Need reproducible builds and supply-chain integrity")
     (decision . "Use Guix channels primary, Nix flakes as fallback")
     (consequences . (reproducibility limited-user-base)))

    (adr-002
     (title . "ReScript for type-safe core")
     (status . accepted)
     (date . "2024")
     (context . "TypeScript eliminated per project goals")
     (decision . "ReScript-first with compile to JS")
     (consequences . (type-safety smaller-community)))

    (adr-003
     (title . "Rust WASM for performance critical paths")
     (status . accepted)
     (date . "2024")
     (context . "Plural rules evaluation is hot path")
     (decision . "CLDR plural rules in Rust WASM")
     (consequences . (10x-performance build-complexity)))

    (adr-004
     (title . "Nickel for configuration")
     (status . accepted)
     (date . "2024")
     (context . "Need type-safe, programmable configuration")
     (decision . "Nickel over JSON/YAML for config")
     (consequences . (type-contracts learning-curve)))))

;;;
;;; Export Combined State
;;;

(define state
  `((metadata . ,metadata)
    (user-context . ,user-context)
    (session-context . ,session-context)
    (focus . ,focus)
    (current-position . ,current-position)
    (project-catalog . ,project-catalog)
    (mvp-route . ,mvp-route)
    (issues . ,issues)
    (questions . ,questions)
    (long-term-roadmap . ,long-term-roadmap)
    (critical-next-actions . ,critical-next-actions)
    (history . ,history)
    (architecture-decisions . ,architecture-decisions)))

;;; STATE.scm ends here
