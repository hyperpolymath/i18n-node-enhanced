@@ocaml.doc("
  Locale - Type-safe locale handling for polyglot-i18n

  Locales are validated at construction time.
")

module LanguageTag = {
  type t = {
    language: string,
    script: option<string>,
    region: option<string>,
    variants: array<string>,
  }

  let languagePattern = %re("/^[a-z]{2,3}$/i")
  let scriptPattern = %re("/^[A-Z][a-z]{3}$/")
  let regionPattern = %re("/^[A-Z]{2}$|^[0-9]{3}$/")

  let parse = (tag: string): option<t> => {
    let parts = tag->String.split("-")
    let len = Array.length(parts)

    if len == 0 {
      None
    } else {
      let lang = parts->Array.getUnsafe(0)
      if !RegExp.test(languagePattern, lang) {
        None
      } else {
        let rest = parts->Array.sliceToEnd(~start=1)
        let script = rest->Array.get(0)->Option.flatMap(s =>
          RegExp.test(scriptPattern, s) ? Some(s) : None
        )
        let regionIdx = script->Option.isSome ? 1 : 0
        let region = rest->Array.get(regionIdx)->Option.flatMap(r =>
          RegExp.test(regionPattern, r) ? Some(r) : None
        )
        let variantIdx = regionIdx + (region->Option.isSome ? 1 : 0)
        let variants = rest->Array.sliceToEnd(~start=variantIdx)

        Some({
          language: lang->String.toLowerCase,
          script,
          region,
          variants,
        })
      }
    }
  }

  let toString = (tag: t): string => {
    let parts = [tag.language]
    tag.script->Option.forEach(s => parts->Array.push(s)->ignore)
    tag.region->Option.forEach(r => parts->Array.push(r)->ignore)
    tag.variants->Array.forEach(v => parts->Array.push(v)->ignore)
    parts->Array.join("-")
  }
}

type t = {
  tag: LanguageTag.t,
  raw: string,
}

let fromString = (s: string): option<t> => {
  LanguageTag.parse(s)->Option.map(tag => {
    tag,
    raw: LanguageTag.toString(tag),
  })
}

let fromStringExn = (s: string): t => {
  switch fromString(s) {
  | Some(locale) => locale
  | None => panic(`Invalid locale: ${s}`)
  }
}

let toString = (locale: t): string => locale.raw
let language = (locale: t): string => locale.tag.language
let region = (locale: t): option<string> => locale.tag.region
let script = (locale: t): option<string> => locale.tag.script
let eq = (a: t, b: t): bool => a.raw == b.raw

let parent = (locale: t): option<t> => {
  switch (locale.tag.region, locale.tag.script) {
  | (Some(_), _) | (None, Some(_)) => fromString(locale.tag.language)
  | (None, None) => None
  }
}

let fallbackChain = (locale: t): array<t> => {
  let result = [locale]
  let current = ref(locale)
  while Option.isSome(parent(current.contents)) {
    switch parent(current.contents) {
    | Some(p) => {
        result->Array.push(p)->ignore
        current := p
      }
    | None => ()
    }
  }
  result
}
