// polyglot-i18n WASM Core - CLDR Plural Rules Engine
// Optimized for size and speed, compliant with Unicode CLDR plural rules
use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Unicode CLDR Plural Categories
/// See: https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules
#[wasm_bindgen]
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum PluralCategory {
    Zero,
    One,
    Two,
    Few,
    Many,
    Other,
}

impl PluralCategory {
    pub fn as_str(&self) -> &'static str {
        match self {
            PluralCategory::Zero => "zero",
            PluralCategory::One => "one",
            PluralCategory::Two => "two",
            PluralCategory::Few => "few",
            PluralCategory::Many => "many",
            PluralCategory::Other => "other",
        }
    }
}

/// Operands for plural rule evaluation per CLDR spec
/// n = absolute value of the source number
/// i = integer digits of n
/// v = number of visible fraction digits (with trailing zeros)
/// w = number of visible fraction digits (without trailing zeros)
/// f = visible fraction digits (with trailing zeros)
/// t = visible fraction digits (without trailing zeros)
#[derive(Clone, Copy, Debug)]
struct PluralOperands {
    n: f64,  // absolute value
    i: u64,  // integer part
    v: usize, // visible fraction digit count (with trailing zeros)
    w: usize, // visible fraction digit count (without trailing zeros)
    f: u64,  // fraction digits (with trailing zeros)
    t: u64,  // fraction digits (without trailing zeros)
}

impl PluralOperands {
    fn from_f64(num: f64) -> Self {
        let n = num.abs();
        let i = n.floor() as u64;

        // For simplicity, handle up to 6 decimal places
        let frac = n - (i as f64);
        let frac_str = format!("{:.6}", frac);
        let frac_digits: String = frac_str.chars().skip(2).collect();

        let v = frac_digits.len();
        let f: u64 = frac_digits.parse().unwrap_or(0);

        let trimmed = frac_digits.trim_end_matches('0');
        let w = trimmed.len();
        let t: u64 = if trimmed.is_empty() { 0 } else { trimmed.parse().unwrap_or(0) };

        PluralOperands { n, i, v, w, f, t }
    }
}

/// CLDR Plural Rules Engine
/// Implements cardinal plural rules for major languages
#[wasm_bindgen]
pub struct PluralRules {
    locale: String,
}

#[wasm_bindgen]
impl PluralRules {
    #[wasm_bindgen(constructor)]
    pub fn new(locale: &str) -> PluralRules {
        // Normalize locale to base language
        let base = locale.split('-').next().unwrap_or(locale);
        PluralRules {
            locale: base.to_lowercase(),
        }
    }

    /// Select the appropriate plural category for a cardinal number
    #[wasm_bindgen]
    pub fn select(&self, n: f64) -> PluralCategory {
        let op = PluralOperands::from_f64(n);

        match self.locale.as_str() {
            // East Asian (no plural distinctions)
            "ja" | "ko" | "zh" | "vi" | "th" | "lo" | "my" => {
                PluralCategory::Other
            }

            // Germanic languages
            "en" | "de" | "nl" | "sv" | "da" | "no" | "nb" | "nn" => {
                self.rule_one_other(op)
            }

            // Romance languages (French, Italian, Portuguese BR)
            "fr" | "it" | "pt" => {
                self.rule_french(op)
            }

            // Spanish
            "es" => {
                self.rule_spanish(op)
            }

            // Russian and East Slavic
            "ru" | "uk" | "be" => {
                self.rule_russian(op)
            }

            // Polish
            "pl" => {
                self.rule_polish(op)
            }

            // Czech and Slovak
            "cs" | "sk" => {
                self.rule_czech(op)
            }

            // Arabic
            "ar" => {
                self.rule_arabic(op)
            }

            // Hebrew
            "he" | "iw" => {
                self.rule_hebrew(op)
            }

            // Romanian
            "ro" | "mo" => {
                self.rule_romanian(op)
            }

            // Latvian
            "lv" => {
                self.rule_latvian(op)
            }

            // Lithuanian
            "lt" => {
                self.rule_lithuanian(op)
            }

            // Slovenian
            "sl" => {
                self.rule_slovenian(op)
            }

            // Irish
            "ga" => {
                self.rule_irish(op)
            }

            // Welsh
            "cy" => {
                self.rule_welsh(op)
            }

            // Maltese
            "mt" => {
                self.rule_maltese(op)
            }

            // Macedonian
            "mk" => {
                self.rule_macedonian(op)
            }

            // Icelandic
            "is" => {
                self.rule_icelandic(op)
            }

            // Filipino/Tagalog
            "fil" | "tl" => {
                self.rule_filipino(op)
            }

            // Turkish, Azerbaijani (no plural, but has one)
            "tr" | "az" => {
                self.rule_one_other(op)
            }

            // Hindi, Bangla
            "hi" | "bn" => {
                self.rule_hindi(op)
            }

            // Default: one/other
            _ => self.rule_one_other(op)
        }
    }

    /// Get the locale being used
    #[wasm_bindgen(js_name = getLocale)]
    pub fn get_locale(&self) -> String {
        self.locale.clone()
    }

    /// Get category as string
    #[wasm_bindgen(js_name = selectString)]
    pub fn select_string(&self, n: f64) -> String {
        self.select(n).as_str().to_string()
    }
}

// Private rule implementations
impl PluralRules {
    /// one: i=1 and v=0; other
    fn rule_one_other(&self, op: PluralOperands) -> PluralCategory {
        if op.i == 1 && op.v == 0 {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// French: one for i=0,1; other
    fn rule_french(&self, op: PluralOperands) -> PluralCategory {
        if op.i == 0 || op.i == 1 {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// Spanish: one: n=1; many: e=0 and end in 6 zeros; other
    fn rule_spanish(&self, op: PluralOperands) -> PluralCategory {
        if op.n == 1.0 {
            PluralCategory::One
        } else if op.i != 0 && op.i % 1000000 == 0 && op.v == 0 {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Russian: complex Slavic rules
    fn rule_russian(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;

        if op.v == 0 {
            if mod10 == 1 && mod100 != 11 {
                PluralCategory::One
            } else if (2..=4).contains(&mod10) && !(12..=14).contains(&mod100) {
                PluralCategory::Few
            } else if mod10 == 0 || (5..=9).contains(&mod10) || (11..=14).contains(&mod100) {
                PluralCategory::Many
            } else {
                PluralCategory::Other
            }
        } else {
            PluralCategory::Other
        }
    }

    /// Polish: complex rules with few/many
    fn rule_polish(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;

        if op.i == 1 && op.v == 0 {
            PluralCategory::One
        } else if op.v == 0 && (2..=4).contains(&mod10) && !(12..=14).contains(&mod100) {
            PluralCategory::Few
        } else if op.v == 0 && (op.i != 1 && (0..=1).contains(&mod10))
            || op.v == 0 && (5..=9).contains(&mod10)
            || op.v == 0 && (12..=14).contains(&mod100) {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Czech/Slovak rules
    fn rule_czech(&self, op: PluralOperands) -> PluralCategory {
        if op.i == 1 && op.v == 0 {
            PluralCategory::One
        } else if (2..=4).contains(&op.i) && op.v == 0 {
            PluralCategory::Few
        } else if op.v != 0 {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Arabic: complex rules with zero, one, two, few, many
    fn rule_arabic(&self, op: PluralOperands) -> PluralCategory {
        let mod100 = op.i % 100;

        if op.n == 0.0 {
            PluralCategory::Zero
        } else if op.n == 1.0 {
            PluralCategory::One
        } else if op.n == 2.0 {
            PluralCategory::Two
        } else if (3..=10).contains(&mod100) {
            PluralCategory::Few
        } else if (11..=99).contains(&mod100) {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Hebrew rules
    fn rule_hebrew(&self, op: PluralOperands) -> PluralCategory {
        if op.i == 1 && op.v == 0 {
            PluralCategory::One
        } else if op.i == 2 && op.v == 0 {
            PluralCategory::Two
        } else if op.v == 0 && !(0..=10).contains(&op.i) && op.i % 10 == 0 {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Romanian rules
    fn rule_romanian(&self, op: PluralOperands) -> PluralCategory {
        let mod100 = op.i % 100;

        if op.i == 1 && op.v == 0 {
            PluralCategory::One
        } else if op.v != 0 || op.n == 0.0 || (op.i != 1 && (1..=19).contains(&mod100)) {
            PluralCategory::Few
        } else {
            PluralCategory::Other
        }
    }

    /// Latvian rules
    fn rule_latvian(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;
        let fmod10 = op.f % 10;
        let fmod100 = op.f % 100;

        if op.n == 0.0 {
            PluralCategory::Zero
        } else if (mod10 == 1 && mod100 != 11) || (op.v == 2 && fmod10 == 1 && fmod100 != 11) || (op.v != 2 && fmod10 == 1) {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// Lithuanian rules
    fn rule_lithuanian(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;

        if mod10 == 1 && !(11..=19).contains(&mod100) {
            PluralCategory::One
        } else if (2..=9).contains(&mod10) && !(11..=19).contains(&mod100) {
            PluralCategory::Few
        } else if op.f != 0 {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Slovenian rules
    fn rule_slovenian(&self, op: PluralOperands) -> PluralCategory {
        let mod100 = op.i % 100;

        if op.v == 0 && mod100 == 1 {
            PluralCategory::One
        } else if op.v == 0 && mod100 == 2 {
            PluralCategory::Two
        } else if (op.v == 0 && (3..=4).contains(&mod100)) || op.v != 0 {
            PluralCategory::Few
        } else {
            PluralCategory::Other
        }
    }

    /// Irish rules (complex)
    fn rule_irish(&self, op: PluralOperands) -> PluralCategory {
        if op.n == 1.0 {
            PluralCategory::One
        } else if op.n == 2.0 {
            PluralCategory::Two
        } else if (3.0..=6.0).contains(&op.n) {
            PluralCategory::Few
        } else if (7.0..=10.0).contains(&op.n) {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Welsh rules
    fn rule_welsh(&self, op: PluralOperands) -> PluralCategory {
        if op.n == 0.0 {
            PluralCategory::Zero
        } else if op.n == 1.0 {
            PluralCategory::One
        } else if op.n == 2.0 {
            PluralCategory::Two
        } else if op.n == 3.0 {
            PluralCategory::Few
        } else if op.n == 6.0 {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Maltese rules
    fn rule_maltese(&self, op: PluralOperands) -> PluralCategory {
        let mod100 = op.i % 100;

        if op.n == 1.0 {
            PluralCategory::One
        } else if op.n == 0.0 || (2..=10).contains(&mod100) {
            PluralCategory::Few
        } else if (11..=19).contains(&mod100) {
            PluralCategory::Many
        } else {
            PluralCategory::Other
        }
    }

    /// Macedonian rules
    fn rule_macedonian(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;
        let fmod10 = op.f % 10;
        let fmod100 = op.f % 100;

        if (op.v == 0 && mod10 == 1 && mod100 != 11) || (fmod10 == 1 && fmod100 != 11) {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// Icelandic rules
    fn rule_icelandic(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let mod100 = op.i % 100;

        if op.t == 0 && mod10 == 1 && mod100 != 11 {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// Filipino/Tagalog rules
    fn rule_filipino(&self, op: PluralOperands) -> PluralCategory {
        let mod10 = op.i % 10;
        let fmod10 = op.f % 10;

        if op.v == 0 && (op.i == 1 || op.i == 2 || op.i == 3)
            || op.v == 0 && mod10 != 4 && mod10 != 6 && mod10 != 9
            || op.v != 0 && fmod10 != 4 && fmod10 != 6 && fmod10 != 9 {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }

    /// Hindi/Bangla rules
    fn rule_hindi(&self, op: PluralOperands) -> PluralCategory {
        if op.i == 0 || op.n == 1.0 {
            PluralCategory::One
        } else {
            PluralCategory::Other
        }
    }
}

/// Main I18n WASM struct with integrated plural rules
#[wasm_bindgen]
pub struct I18nWasm {
    catalogs: HashMap<String, HashMap<String, String>>,
    plural_catalogs: HashMap<String, HashMap<String, PluralForms>>,
    current_locale: String,
    default_locale: String,
    fallbacks: HashMap<String, String>,
}

#[derive(Clone, Serialize, Deserialize)]
struct PluralForms {
    zero: Option<String>,
    one: Option<String>,
    two: Option<String>,
    few: Option<String>,
    many: Option<String>,
    other: String,
}

#[derive(Serialize, Deserialize)]
pub struct Config {
    pub locales: Vec<String>,
    pub default_locale: String,
    #[serde(default)]
    pub fallbacks: HashMap<String, String>,
}

#[wasm_bindgen]
impl I18nWasm {
    #[wasm_bindgen(constructor)]
    pub fn new(config_json: &str) -> Result<I18nWasm, JsValue> {
        let config: Config = serde_json::from_str(config_json)
            .map_err(|e| JsValue::from_str(&format!("Invalid config: {}", e)))?;

        Ok(I18nWasm {
            catalogs: HashMap::new(),
            plural_catalogs: HashMap::new(),
            current_locale: config.default_locale.clone(),
            default_locale: config.default_locale,
            fallbacks: config.fallbacks,
        })
    }

    #[wasm_bindgen(js_name = loadCatalog)]
    pub fn load_catalog(&mut self, locale: &str, catalog_json: &str) -> Result<(), JsValue> {
        let catalog: HashMap<String, serde_json::Value> = serde_json::from_str(catalog_json)
            .map_err(|e| JsValue::from_str(&format!("Invalid catalog: {}", e)))?;

        let mut strings: HashMap<String, String> = HashMap::new();
        let mut plurals: HashMap<String, PluralForms> = HashMap::new();

        for (key, value) in catalog {
            match value {
                serde_json::Value::String(s) => {
                    strings.insert(key, s);
                }
                serde_json::Value::Object(obj) => {
                    // Check if it's plural forms (has "other" key)
                    if obj.contains_key("other") {
                        let forms = PluralForms {
                            zero: obj.get("zero").and_then(|v| v.as_str()).map(String::from),
                            one: obj.get("one").and_then(|v| v.as_str()).map(String::from),
                            two: obj.get("two").and_then(|v| v.as_str()).map(String::from),
                            few: obj.get("few").and_then(|v| v.as_str()).map(String::from),
                            many: obj.get("many").and_then(|v| v.as_str()).map(String::from),
                            other: obj.get("other")
                                .and_then(|v| v.as_str())
                                .map(String::from)
                                .unwrap_or_default(),
                        };
                        plurals.insert(key, forms);
                    }
                    // TODO: Handle nested objects for dot notation
                }
                _ => {}
            }
        }

        self.catalogs.insert(locale.to_string(), strings);
        self.plural_catalogs.insert(locale.to_string(), plurals);
        Ok(())
    }

    #[wasm_bindgen(js_name = translate)]
    pub fn translate(&self, key: &str) -> String {
        // Try current locale
        if let Some(result) = self.try_locale(&self.current_locale, key) {
            return result;
        }

        // Try fallback
        if let Some(fallback) = self.fallbacks.get(&self.current_locale) {
            if let Some(result) = self.try_locale(fallback, key) {
                return result;
            }
        }

        // Try default locale
        if let Some(result) = self.try_locale(&self.default_locale, key) {
            return result;
        }

        // Return key as fallback
        key.to_string()
    }

    fn try_locale(&self, locale: &str, key: &str) -> Option<String> {
        self.catalogs
            .get(locale)
            .and_then(|catalog| catalog.get(key))
            .cloned()
    }

    #[wasm_bindgen(js_name = translatePlural)]
    pub fn translate_plural(&self, key: &str, count: f64) -> String {
        let rules = PluralRules::new(&self.current_locale);
        let category = rules.select(count);

        // Try to find plural forms
        if let Some(forms) = self.plural_catalogs
            .get(&self.current_locale)
            .and_then(|catalog| catalog.get(key))
        {
            let template = match category {
                PluralCategory::Zero => forms.zero.as_ref().unwrap_or(&forms.other),
                PluralCategory::One => forms.one.as_ref().unwrap_or(&forms.other),
                PluralCategory::Two => forms.two.as_ref().unwrap_or(&forms.other),
                PluralCategory::Few => forms.few.as_ref().unwrap_or(&forms.other),
                PluralCategory::Many => forms.many.as_ref().unwrap_or(&forms.other),
                PluralCategory::Other => &forms.other,
            };

            // Replace %d or %s with count
            return template
                .replace("%d", &count.to_string())
                .replace("%s", &count.to_string());
        }

        // Fallback to key
        key.to_string()
    }

    #[wasm_bindgen(js_name = setLocale)]
    pub fn set_locale(&mut self, locale: &str) -> String {
        self.current_locale = locale.to_string();
        locale.to_string()
    }

    #[wasm_bindgen(js_name = getLocale)]
    pub fn get_locale(&self) -> String {
        self.current_locale.clone()
    }

    #[wasm_bindgen(js_name = hasKey)]
    pub fn has_key(&self, key: &str) -> bool {
        self.catalogs
            .get(&self.current_locale)
            .map(|catalog| catalog.contains_key(key))
            .unwrap_or(false)
    }

    #[wasm_bindgen(js_name = getCatalogSize)]
    pub fn get_catalog_size(&self) -> usize {
        self.catalogs
            .get(&self.current_locale)
            .map(|catalog| catalog.len())
            .unwrap_or(0)
    }

    #[wasm_bindgen(js_name = getDefaultLocale)]
    pub fn get_default_locale(&self) -> String {
        self.default_locale.clone()
    }
}

/// Mustache-style interpolation
#[wasm_bindgen(js_name = interpolateMustache)]
pub fn interpolate_mustache(template: &str, values_json: &str) -> Result<String, JsValue> {
    let values: HashMap<String, String> = serde_json::from_str(values_json)
        .map_err(|e| JsValue::from_str(&format!("Invalid values: {}", e)))?;

    let mut result = template.to_string();
    for (key, value) in values {
        result = result.replace(&format!("{{{{{}}}}}", key), &value);
    }
    Ok(result)
}

/// sprintf-style formatting (minimal implementation)
#[wasm_bindgen(js_name = formatSprintf)]
pub fn format_sprintf(template: &str, args_json: &str) -> Result<String, JsValue> {
    let args: Vec<String> = serde_json::from_str(args_json)
        .map_err(|e| JsValue::from_str(&format!("Invalid args: {}", e)))?;

    let mut result = template.to_string();
    for arg in args {
        // Replace first occurrence of %s or %d
        if let Some(pos) = result.find("%s") {
            result = format!("{}{}{}", &result[..pos], arg, &result[pos+2..]);
        } else if let Some(pos) = result.find("%d") {
            result = format!("{}{}{}", &result[..pos], arg, &result[pos+2..]);
        }
    }
    Ok(result)
}

/// Initialize WASM module
#[wasm_bindgen(js_name = initWasm)]
pub fn init() {
    #[cfg(feature = "console_error_panic_hook")]
    console_error_panic_hook::set_once();
}

/// Get plural category for a number in a locale (standalone function)
#[wasm_bindgen(js_name = getPluralCategory)]
pub fn get_plural_category(locale: &str, n: f64) -> String {
    let rules = PluralRules::new(locale);
    rules.select(n).as_str().to_string()
}

/// Get all supported locales for plural rules
#[wasm_bindgen(js_name = getSupportedPluralLocales)]
pub fn get_supported_plural_locales() -> String {
    let locales = vec![
        "ar", "az", "be", "bn", "cs", "cy", "da", "de", "en", "es",
        "fil", "fr", "ga", "he", "hi", "is", "it", "ja", "ko", "lt",
        "lv", "mk", "mt", "my", "nb", "nl", "nn", "no", "pl", "pt",
        "ro", "ru", "sk", "sl", "sv", "th", "tl", "tr", "uk", "vi", "zh"
    ];
    serde_json::to_string(&locales).unwrap_or_else(|_| "[]".to_string())
}

// ============================================================================
// RelativeTime - Human-readable relative time formatting
// ============================================================================

/// Time units for relative time
#[wasm_bindgen]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TimeUnit {
    Second,
    Minute,
    Hour,
    Day,
    Week,
    Month,
    Year,
}

/// Formatting style
#[wasm_bindgen]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RelativeTimeStyle {
    Long,   // "3 days ago"
    Short,  // "3d ago"
    Narrow, // "3d"
}

/// Numeric display option
#[wasm_bindgen]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NumericOption {
    Always, // "1 day ago"
    Auto,   // "yesterday"
}

/// RelativeTime formatter
#[wasm_bindgen]
pub struct RelativeTimeFormat {
    locale: String,
    style: RelativeTimeStyle,
    numeric: NumericOption,
}

#[wasm_bindgen]
impl RelativeTimeFormat {
    #[wasm_bindgen(constructor)]
    pub fn new(locale: &str) -> RelativeTimeFormat {
        let base = locale.split('-').next().unwrap_or(locale);
        RelativeTimeFormat {
            locale: base.to_lowercase(),
            style: RelativeTimeStyle::Long,
            numeric: NumericOption::Auto,
        }
    }

    #[wasm_bindgen(js_name = setStyle)]
    pub fn set_style(&mut self, style: RelativeTimeStyle) {
        self.style = style;
    }

    #[wasm_bindgen(js_name = setNumeric)]
    pub fn set_numeric(&mut self, numeric: NumericOption) {
        self.numeric = numeric;
    }

    /// Format a difference in seconds
    #[wasm_bindgen]
    pub fn format(&self, diff_seconds: f64) -> String {
        let (unit, value) = self.select_unit(diff_seconds);
        self.format_value(value, unit)
    }

    /// Format with explicit unit
    #[wasm_bindgen(js_name = formatUnit)]
    pub fn format_unit(&self, value: f64, unit: TimeUnit) -> String {
        self.format_value(value, unit)
    }

    fn select_unit(&self, diff_seconds: f64) -> (TimeUnit, f64) {
        let abs_diff = diff_seconds.abs();

        if abs_diff >= 31536000.0 * 0.5 {
            (TimeUnit::Year, diff_seconds / 31536000.0)
        } else if abs_diff >= 2628000.0 * 0.5 {
            (TimeUnit::Month, diff_seconds / 2628000.0)
        } else if abs_diff >= 604800.0 * 0.5 {
            (TimeUnit::Week, diff_seconds / 604800.0)
        } else if abs_diff >= 86400.0 * 0.5 {
            (TimeUnit::Day, diff_seconds / 86400.0)
        } else if abs_diff >= 3600.0 * 0.5 {
            (TimeUnit::Hour, diff_seconds / 3600.0)
        } else if abs_diff >= 60.0 * 0.5 {
            (TimeUnit::Minute, diff_seconds / 60.0)
        } else {
            (TimeUnit::Second, diff_seconds)
        }
    }

    fn format_value(&self, value: f64, unit: TimeUnit) -> String {
        let abs_value = value.abs();
        let rounded = abs_value.round() as i64;
        let is_past = value < 0.0;

        // Check for special cases with Auto numeric
        if self.numeric == NumericOption::Auto {
            if abs_value < 10.0 && unit == TimeUnit::Second {
                return self.get_now_string();
            }
            if rounded == 1 {
                if let Some(special) = self.get_special_name(unit, is_past) {
                    return special;
                }
            }
        }

        let unit_name = self.get_unit_name(unit, rounded);
        self.format_with_direction(rounded, &unit_name, is_past)
    }

    fn get_now_string(&self) -> String {
        match self.locale.as_str() {
            "de" => "gerade eben".to_string(),
            "fr" => "à l'instant".to_string(),
            "es" => "ahora mismo".to_string(),
            "ru" => "только что".to_string(),
            "ja" => "たった今".to_string(),
            "zh" => "刚刚".to_string(),
            "ar" => "الآن".to_string(),
            _ => "just now".to_string(),
        }
    }

    fn get_special_name(&self, unit: TimeUnit, is_past: bool) -> Option<String> {
        match (&self.locale[..], unit, is_past) {
            ("en", TimeUnit::Day, true) => Some("yesterday".to_string()),
            ("en", TimeUnit::Day, false) => Some("tomorrow".to_string()),
            ("en", TimeUnit::Week, true) => Some("last week".to_string()),
            ("en", TimeUnit::Week, false) => Some("next week".to_string()),
            ("en", TimeUnit::Month, true) => Some("last month".to_string()),
            ("en", TimeUnit::Month, false) => Some("next month".to_string()),
            ("en", TimeUnit::Year, true) => Some("last year".to_string()),
            ("en", TimeUnit::Year, false) => Some("next year".to_string()),
            ("de", TimeUnit::Day, true) => Some("gestern".to_string()),
            ("de", TimeUnit::Day, false) => Some("morgen".to_string()),
            ("fr", TimeUnit::Day, true) => Some("hier".to_string()),
            ("fr", TimeUnit::Day, false) => Some("demain".to_string()),
            ("es", TimeUnit::Day, true) => Some("ayer".to_string()),
            ("es", TimeUnit::Day, false) => Some("mañana".to_string()),
            ("ja", TimeUnit::Day, true) => Some("昨日".to_string()),
            ("ja", TimeUnit::Day, false) => Some("明日".to_string()),
            ("zh", TimeUnit::Day, true) => Some("昨天".to_string()),
            ("zh", TimeUnit::Day, false) => Some("明天".to_string()),
            _ => None,
        }
    }

    fn get_unit_name(&self, unit: TimeUnit, count: i64) -> String {
        let rules = PluralRules::new(&self.locale);
        let category = rules.select(count as f64);
        let is_plural = category != PluralCategory::One;

        match (&self.locale[..], unit, self.style, is_plural) {
            // English
            ("en", TimeUnit::Second, RelativeTimeStyle::Long, false) => "second".to_string(),
            ("en", TimeUnit::Second, RelativeTimeStyle::Long, true) => "seconds".to_string(),
            ("en", TimeUnit::Minute, RelativeTimeStyle::Long, false) => "minute".to_string(),
            ("en", TimeUnit::Minute, RelativeTimeStyle::Long, true) => "minutes".to_string(),
            ("en", TimeUnit::Hour, RelativeTimeStyle::Long, false) => "hour".to_string(),
            ("en", TimeUnit::Hour, RelativeTimeStyle::Long, true) => "hours".to_string(),
            ("en", TimeUnit::Day, RelativeTimeStyle::Long, false) => "day".to_string(),
            ("en", TimeUnit::Day, RelativeTimeStyle::Long, true) => "days".to_string(),
            ("en", TimeUnit::Week, RelativeTimeStyle::Long, false) => "week".to_string(),
            ("en", TimeUnit::Week, RelativeTimeStyle::Long, true) => "weeks".to_string(),
            ("en", TimeUnit::Month, RelativeTimeStyle::Long, false) => "month".to_string(),
            ("en", TimeUnit::Month, RelativeTimeStyle::Long, true) => "months".to_string(),
            ("en", TimeUnit::Year, RelativeTimeStyle::Long, false) => "year".to_string(),
            ("en", TimeUnit::Year, RelativeTimeStyle::Long, true) => "years".to_string(),
            // Short/Narrow English
            ("en", TimeUnit::Second, RelativeTimeStyle::Short, _) => "sec".to_string(),
            ("en", TimeUnit::Minute, RelativeTimeStyle::Short, _) => "min".to_string(),
            ("en", TimeUnit::Hour, RelativeTimeStyle::Short, _) => "hr".to_string(),
            ("en", TimeUnit::Day, RelativeTimeStyle::Short, _) => "day".to_string(),
            ("en", TimeUnit::Week, RelativeTimeStyle::Short, _) => "wk".to_string(),
            ("en", TimeUnit::Month, RelativeTimeStyle::Short, _) => "mo".to_string(),
            ("en", TimeUnit::Year, RelativeTimeStyle::Short, _) => "yr".to_string(),
            ("en", TimeUnit::Second, RelativeTimeStyle::Narrow, _) => "s".to_string(),
            ("en", TimeUnit::Minute, RelativeTimeStyle::Narrow, _) => "m".to_string(),
            ("en", TimeUnit::Hour, RelativeTimeStyle::Narrow, _) => "h".to_string(),
            ("en", TimeUnit::Day, RelativeTimeStyle::Narrow, _) => "d".to_string(),
            ("en", TimeUnit::Week, RelativeTimeStyle::Narrow, _) => "w".to_string(),
            ("en", TimeUnit::Month, RelativeTimeStyle::Narrow, _) => "mo".to_string(),
            ("en", TimeUnit::Year, RelativeTimeStyle::Narrow, _) => "y".to_string(),
            // Default fallback
            (_, TimeUnit::Second, _, _) => "seconds".to_string(),
            (_, TimeUnit::Minute, _, _) => "minutes".to_string(),
            (_, TimeUnit::Hour, _, _) => "hours".to_string(),
            (_, TimeUnit::Day, _, _) => "days".to_string(),
            (_, TimeUnit::Week, _, _) => "weeks".to_string(),
            (_, TimeUnit::Month, _, _) => "months".to_string(),
            (_, TimeUnit::Year, _, _) => "years".to_string(),
        }
    }

    fn format_with_direction(&self, value: i64, unit_name: &str, is_past: bool) -> String {
        match self.locale.as_str() {
            "ja" | "zh" | "ko" => {
                let marker = if is_past { "前" } else { "後" };
                format!("{}{}{}", value, unit_name, marker)
            }
            "de" => {
                if is_past {
                    format!("vor {} {}", value, unit_name)
                } else {
                    format!("in {} {}", value, unit_name)
                }
            }
            "fr" => {
                if is_past {
                    format!("il y a {} {}", value, unit_name)
                } else {
                    format!("dans {} {}", value, unit_name)
                }
            }
            "es" => {
                if is_past {
                    format!("hace {} {}", value, unit_name)
                } else {
                    format!("en {} {}", value, unit_name)
                }
            }
            "ru" => {
                if is_past {
                    format!("{} {} назад", value, unit_name)
                } else {
                    format!("через {} {}", value, unit_name)
                }
            }
            _ => {
                // English default
                if is_past {
                    format!("{} {} ago", value, unit_name)
                } else {
                    format!("in {} {}", value, unit_name)
                }
            }
        }
    }
}

/// Format relative time from timestamp (standalone function)
#[wasm_bindgen(js_name = formatRelativeTime)]
pub fn format_relative_time(locale: &str, diff_seconds: f64) -> String {
    let formatter = RelativeTimeFormat::new(locale);
    formatter.format(diff_seconds)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_english_plurals() {
        let rules = PluralRules::new("en");
        assert_eq!(rules.select(1.0), PluralCategory::One);
        assert_eq!(rules.select(0.0), PluralCategory::Other);
        assert_eq!(rules.select(2.0), PluralCategory::Other);
        assert_eq!(rules.select(1.5), PluralCategory::Other);
    }

    #[test]
    fn test_russian_plurals() {
        let rules = PluralRules::new("ru");
        assert_eq!(rules.select(1.0), PluralCategory::One);
        assert_eq!(rules.select(2.0), PluralCategory::Few);
        assert_eq!(rules.select(5.0), PluralCategory::Many);
        assert_eq!(rules.select(21.0), PluralCategory::One);
        assert_eq!(rules.select(22.0), PluralCategory::Few);
        assert_eq!(rules.select(25.0), PluralCategory::Many);
    }

    #[test]
    fn test_arabic_plurals() {
        let rules = PluralRules::new("ar");
        assert_eq!(rules.select(0.0), PluralCategory::Zero);
        assert_eq!(rules.select(1.0), PluralCategory::One);
        assert_eq!(rules.select(2.0), PluralCategory::Two);
        assert_eq!(rules.select(3.0), PluralCategory::Few);
        assert_eq!(rules.select(11.0), PluralCategory::Many);
    }

    #[test]
    fn test_japanese_plurals() {
        let rules = PluralRules::new("ja");
        assert_eq!(rules.select(0.0), PluralCategory::Other);
        assert_eq!(rules.select(1.0), PluralCategory::Other);
        assert_eq!(rules.select(100.0), PluralCategory::Other);
    }
}
