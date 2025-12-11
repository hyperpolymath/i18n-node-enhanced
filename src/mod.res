@@ocaml.doc("
  polyglot-i18n - ReScript-first internationalization for Deno

  Usage:
    import { I18n, Locale, Catalog, Plural, RelativeTime } from \"polyglot-i18n\"

    let i18n = I18n.fromBuilder(
      I18n.Config.make()
      ->I18n.Config.withLocales([\"en\", \"de\", \"fr\"])
      ->I18n.Config.withDefaultLocale(\"en\")
      ->I18n.Config.withObjectNotation(true)
    )

    // Relative time formatting
    let rtf = RelativeTime.make(Locale.fromString(\"en\")->Option.getOr(Locale.defaultLocale))
    rtf->RelativeTime.format(-86400.0)  // \"yesterday\" or \"1 day ago\"

  SPDX-License-Identifier: AGPL-3.0-or-later
")

// Re-export all public modules
module Locale = Locale
module Catalog = Catalog
module Plural = Plural
module I18n = I18n
module RelativeTime = RelativeTime
