@@ocaml.doc("
  Catalog - Immutable translation catalog with structural sharing

  Catalogs are immutable data structures that hold translations.
  Uses Dict for O(1) key lookup.
")

@ocaml.doc("A translation value - either a simple string or plural forms")
type rec translationValue =
  | Simple(string)
  | Plural({
      zero: option<string>,
      one: option<string>,
      two: option<string>,
      few: option<string>,
      many: option<string>,
      other: string,
    })
  | Nested(translations)
and translations = Dict.t<translationValue>

@ocaml.doc("Catalog metadata")
type metadata = {
  version: option<string>,
  lastModified: option<float>,
  source: option<string>,
}

@ocaml.doc("A catalog holds translations for a single locale")
type t = {
  locale: string,
  translations: translations,
  metadata: metadata,
}

@ocaml.doc("Create an empty catalog for a locale")
let empty = (locale: string): t => {
  locale,
  translations: Dict.make(),
  metadata: {
    version: None,
    lastModified: None,
    source: None,
  },
}

@ocaml.doc("Get a translation by key, supporting dot notation")
let get = (catalog: t, key: string): option<translationValue> => {
  let parts = key->String.split(".")

  let rec traverse = (translations: translations, path: array<string>, idx: int): option<translationValue> => {
    if idx >= Array.length(path) {
      None
    } else if idx == Array.length(path) - 1 {
      translations->Dict.get(path[idx]->Option.getOr(""))
    } else {
      switch translations->Dict.get(path[idx]->Option.getOr("")) {
      | Some(Nested(nested)) => traverse(nested, path, idx + 1)
      | _ => None
      }
    }
  }

  if Array.length(parts) == 0 {
    None
  } else {
    traverse(catalog.translations, parts, 0)
  }
}

@ocaml.doc("Get a simple string translation")
let getString = (catalog: t, key: string): option<string> => {
  switch get(catalog, key) {
  | Some(Simple(s)) => Some(s)
  | Some(Plural({other})) => Some(other)
  | _ => None
  }
}

@ocaml.doc("Set a translation, returning a new catalog")
let set = (catalog: t, key: string, value: translationValue): t => {
  // For simplicity, only handle single-level keys for now
  let newTranslations = Dict.copy(catalog.translations)
  newTranslations->Dict.set(key, value)

  {
    ...catalog,
    translations: newTranslations,
    metadata: {
      ...catalog.metadata,
      lastModified: Some(Date.now()),
    },
  }
}

@ocaml.doc("Check if a key exists")
let has = (catalog: t, key: string): bool => get(catalog, key)->Option.isSome

@ocaml.doc("Get all keys in the catalog (flattened)")
let keys = (catalog: t): array<string> => {
  Dict.keysToArray(catalog.translations)
}

@ocaml.doc("Merge two catalogs, with the second taking precedence")
let merge = (base: t, overlay: t): t => {
  let result: translations = Dict.copy(base.translations)

  let overlayKeys = Dict.keysToArray(overlay.translations)
  overlayKeys->Array.forEach(key => {
    switch overlay.translations->Dict.get(key) {
    | Some(value) => result->Dict.set(key, value)
    | None => ()
    }
  })

  {
    locale: overlay.locale,
    translations: result,
    metadata: overlay.metadata,
  }
}

@ocaml.doc("Parse a catalog from JSON")
let fromJson = (locale: string, json: JSON.t): result<t, string> => {
  let rec parseValue = (json: JSON.t): option<translationValue> => {
    switch json {
    | JSON.String(s) => Some(Simple(s))
    | JSON.Object(obj) => {
        // Check if it's plural forms or nested
        let hasPlural = obj->Dict.get("other")->Option.isSome
        if hasPlural {
          let getStr = key =>
            obj->Dict.get(key)->Option.flatMap(v =>
              switch v {
              | JSON.String(s) => Some(s)
              | _ => None
              }
            )
          switch getStr("other") {
          | Some(other) =>
            Some(
              Plural({
                zero: getStr("zero"),
                one: getStr("one"),
                two: getStr("two"),
                few: getStr("few"),
                many: getStr("many"),
                other,
              }),
            )
          | None => None
          }
        } else {
          // Nested translations
          let nested = Dict.make()
          obj->Dict.forEachWithKey((value, key) => {
            switch parseValue(value) {
            | Some(v) => nested->Dict.set(key, v)
            | None => ()
            }
          })
          Some(Nested(nested))
        }
      }
    | _ => None
    }
  }

  switch json {
  | JSON.Object(obj) => {
      let translations = Dict.make()
      obj->Dict.forEachWithKey((value, key) => {
        switch parseValue(value) {
        | Some(v) => translations->Dict.set(key, v)
        | None => ()
        }
      })
      Ok({
        locale,
        translations,
        metadata: {
          version: None,
          lastModified: Some(Date.now()),
          source: None,
        },
      })
    }
  | _ => Error("Expected JSON object at root")
  }
}

@ocaml.doc("Serialize a catalog to JSON")
let toJson = (catalog: t): JSON.t => {
  let rec valueToJson = (value: translationValue): JSON.t => {
    switch value {
    | Simple(s) => JSON.String(s)
    | Plural({zero, one, two, few, many, other}) => {
        let obj = Dict.make()
        zero->Option.forEach(v => obj->Dict.set("zero", JSON.String(v)))
        one->Option.forEach(v => obj->Dict.set("one", JSON.String(v)))
        two->Option.forEach(v => obj->Dict.set("two", JSON.String(v)))
        few->Option.forEach(v => obj->Dict.set("few", JSON.String(v)))
        many->Option.forEach(v => obj->Dict.set("many", JSON.String(v)))
        obj->Dict.set("other", JSON.String(other))
        JSON.Object(obj)
      }
    | Nested(nested) => {
        let obj = Dict.make()
        nested->Dict.forEachWithKey((value, key) => {
          obj->Dict.set(key, valueToJson(value))
        })
        JSON.Object(obj)
      }
    }
  }

  let obj = Dict.make()
  catalog.translations->Dict.forEachWithKey((value, key) => {
    obj->Dict.set(key, valueToJson(value))
  })
  JSON.Object(obj)
}
