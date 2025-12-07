@@ocaml.doc("
  Plural - CLDR plural rule evaluation
  Uses WASM when available, falls back to ReScript.
")

type category = Zero | One | Two | Few | Many | Other

let categoryToString = (cat: category): string => {
  switch cat {
  | Zero => "zero"
  | One => "one"
  | Two => "two"
  | Few => "few"
  | Many => "many"
  | Other => "other"
  }
}

let categoryFromString = (s: string): option<category> => {
  switch s {
  | "zero" => Some(Zero)
  | "one" => Some(One)
  | "two" => Some(Two)
  | "few" => Some(Few)
  | "many" => Some(Many)
  | "other" => Some(Other)
  | _ => None
  }
}

type operands = {
  n: float,
  i: float,
  v: int,
  w: int,
  f: float,
  t: float,
}

let getOperands = (n: float): operands => {
  let absN = Math.abs(n)
  let str = Float.toString(absN)
  let parts = str->String.split(".")

  let intPart = parts->Array.get(0)->Option.getOr("0")
  let fracPart = parts->Array.get(1)->Option.getOr("")

  let i = Float.fromString(intPart)->Option.getOr(0.0)
  let v = String.length(fracPart)
  let fracWithoutZeros = fracPart->String.replaceRegExp(%re("/0+$/g"), "")
  let w = String.length(fracWithoutZeros)
  let f = Float.fromString(fracPart)->Option.getOr(0.0)
  let t = Float.fromString(fracWithoutZeros)->Option.getOr(0.0)

  {n: absN, i, v, w, f, t}
}

module Wasm = {
  type wasmModule
  @val external wasmModule: option<wasmModule> = "globalThis.__polyglot_plural_wasm"
  @send external evaluate: (wasmModule, float, string) => string = "evaluate_plural"
  let isAvailable = (): bool => wasmModule->Option.isSome
  let evaluateCategory = (n: float, locale: string): option<category> => {
    wasmModule->Option.flatMap(wasm => categoryFromString(wasm->evaluate(n, locale)))
  }
}

module Rules = {
  let en = (op: operands): category => op.i == 1.0 && op.v == 0 ? One : Other
  let de = en
  let fr = (op: operands): category => op.i == 0.0 || op.i == 1.0 ? One : Other

  let ru = (op: operands): category => {
    let mod10 = mod_float(op.i, 10.0)
    let mod100 = mod_float(op.i, 100.0)
    if op.v == 0 {
      if mod10 == 1.0 && mod100 != 11.0 { One }
      else if mod10 >= 2.0 && mod10 <= 4.0 && (mod100 < 12.0 || mod100 > 14.0) { Few }
      else if mod10 == 0.0 || (mod10 >= 5.0 && mod10 <= 9.0) || (mod100 >= 11.0 && mod100 <= 14.0) { Many }
      else { Other }
    } else { Other }
  }

  let ar = (op: operands): category => {
    let mod100 = mod_float(op.n, 100.0)
    if op.n == 0.0 { Zero }
    else if op.n == 1.0 { One }
    else if op.n == 2.0 { Two }
    else if mod100 >= 3.0 && mod100 <= 10.0 { Few }
    else if mod100 >= 11.0 && mod100 <= 99.0 { Many }
    else { Other }
  }

  let pl = (op: operands): category => {
    let mod10 = mod_float(op.i, 10.0)
    let mod100 = mod_float(op.i, 100.0)
    if op.v == 0 {
      if op.i == 1.0 { One }
      else if mod10 >= 2.0 && mod10 <= 4.0 && (mod100 < 12.0 || mod100 > 14.0) { Few }
      else { Many }
    } else { Other }
  }

  let ja = (_: operands): category => Other
  let zh = ja
  let ko = ja
}

let getRuleForLocale = (locale: string): option<operands => category> => {
  let lang = locale->String.split("-")->Array.get(0)->Option.getOr(locale)->String.toLowerCase
  switch lang {
  | "en" => Some(Rules.en)
  | "de" => Some(Rules.de)
  | "fr" => Some(Rules.fr)
  | "ru" => Some(Rules.ru)
  | "ar" => Some(Rules.ar)
  | "pl" => Some(Rules.pl)
  | "ja" | "zh" | "ko" => Some(Rules.ja)
  | _ => None
  }
}

let select = (n: float, locale: string): category => {
  switch Wasm.evaluateCategory(n, locale) {
  | Some(cat) => cat
  | None =>
    switch getRuleForLocale(locale) {
    | Some(rule) => rule(getOperands(n))
    | None => Other
    }
  }
}
