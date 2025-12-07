@@ocaml.doc("
  I18n - Main API for polyglot-i18n
  Type-safe, immutable internationalization.
")

type config = {
  locales: array<string>,
  defaultLocale: string,
  fallbacks: Dict.t<string>,
  objectNotation: bool,
}

type t = {
  config: config,
  catalogs: Dict.t<Catalog.t>,
  currentLocale: string,
}

module Config = {
  type builder = {
    mutable locales: array<string>,
    mutable defaultLocale: option<string>,
    mutable fallbacks: Dict.t<string>,
    mutable objectNotation: bool,
  }

  let make = (): builder => {
    locales: [],
    defaultLocale: None,
    fallbacks: Dict.make(),
    objectNotation: false,
  }

  let withLocales = (b, locales) => { b.locales = locales; b }
  let withDefaultLocale = (b, locale) => { b.defaultLocale = Some(locale); b }
  let withFallback = (b, from, to_) => { b.fallbacks->Dict.set(from, to_); b }
  let withObjectNotation = (b, enabled) => { b.objectNotation = enabled; b }

  let build = (b: builder): result<config, string> => {
    if Array.length(b.locales) == 0 {
      Error("At least one locale required")
    } else {
      let defaultLocale = b.defaultLocale->Option.getOr(b.locales->Array.getUnsafe(0))
      Ok({
        locales: b.locales,
        defaultLocale,
        fallbacks: b.fallbacks,
        objectNotation: b.objectNotation,
      })
    }
  }
}

let make = (config: config): t => {
  let catalogs = Dict.make()
  config.locales->Array.forEach(locale => {
    catalogs->Dict.set(locale, Catalog.empty(locale))
  })
  { config, catalogs, currentLocale: config.defaultLocale }
}

let fromBuilder = (builder: Config.builder): result<t, string> => {
  Config.build(builder)->Result.map(make)
}

let getLocale = (i18n: t): string => i18n.currentLocale

let setLocale = (i18n: t, locale: string): t => {
  let resolved = if i18n.config.locales->Array.includes(locale) {
    locale
  } else {
    i18n.config.fallbacks->Dict.get(locale)->Option.getOr(i18n.config.defaultLocale)
  }
  {...i18n, currentLocale: resolved}
}

let getCatalog = (i18n: t, locale: string): option<Catalog.t> => {
  i18n.catalogs->Dict.get(locale)
}

let loadTranslations = (i18n: t, locale: string, json: JSON.t): result<t, string> => {
  Catalog.fromJson(locale, json)->Result.map(catalog => {
    let existing = i18n.catalogs->Dict.get(locale)->Option.getOr(Catalog.empty(locale))
    let merged = Catalog.merge(existing, catalog)
    let newCatalogs = Dict.copy(i18n.catalogs)
    newCatalogs->Dict.set(locale, merged)
    {...i18n, catalogs: newCatalogs}
  })
}

module Interpolate = {
  let mustache = (template: string, values: Dict.t<string>): string => {
    let result = ref(template)
    values->Dict.forEachWithKey((value, key) => {
      result := result.contents->String.replaceAll(`{{${key}}}`, value)
    })
    result.contents
  }

  let sprintf = (template: string, args: array<string>): string => {
    let result = ref(template)
    args->Array.forEach(arg => {
      result := result.contents->String.replaceRegExp(%re("/%[sd]/"), arg)
    })
    result.contents
  }
}

let translate = (i18n: t, key: string): string => {
  let tryLocale = (locale) => {
    i18n.catalogs->Dict.get(locale)->Option.flatMap(cat => Catalog.getString(cat, key))
  }

  switch tryLocale(i18n.currentLocale) {
  | Some(t) => t
  | None =>
    switch i18n.config.fallbacks->Dict.get(i18n.currentLocale)->Option.flatMap(tryLocale) {
    | Some(t) => t
    | None =>
      switch tryLocale(i18n.config.defaultLocale) {
      | Some(t) => t
      | None => key
      }
    }
  }
}

let translateWith = (i18n: t, key: string, values: Dict.t<string>): string => {
  translate(i18n, key)->Interpolate.mustache(values)
}

let translateArgs = (i18n: t, key: string, args: array<string>): string => {
  translate(i18n, key)->Interpolate.sprintf(args)
}

let translatePlural = (i18n: t, singular: string, plural: string, count: float): string => {
  let category = Plural.select(count, i18n.currentLocale)
  let template = switch category {
  | Plural.One => singular
  | _ => plural
  }
  template->String.replaceRegExp(%re("/%[sd]/"), Float.toString(count))
}

let __ = translate
let __n = translatePlural
let getLocales = (i18n: t): array<string> => i18n.config.locales
let getDefaultLocale = (i18n: t): string => i18n.config.defaultLocale

let hasKey = (i18n: t, key: string): bool => {
  i18n.catalogs->Dict.get(i18n.currentLocale)
    ->Option.map(cat => Catalog.has(cat, key))
    ->Option.getOr(false)
}

let getAllKeys = (i18n: t): array<string> => {
  i18n.catalogs->Dict.get(i18n.currentLocale)
    ->Option.map(Catalog.keys)
    ->Option.getOr([])
}

let exportCatalog = (i18n: t, locale: string): option<JSON.t> => {
  i18n.catalogs->Dict.get(locale)->Option.map(Catalog.toJson)
}
