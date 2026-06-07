# Country name / ISO3 helpers for flagcdn.com (ISO 3166-1 alpha-2)

get_country_flag_code <- function(country_name) {
  if (is.null(country_name) || is.na(country_name)) return("un")

  country_lower <- tolower(country_name)

  country_codes <- c(
    "united states" = "us", "united states of america" = "us",
    "canada" = "ca",
    "united kingdom" = "gb", "britain" = "gb",
    "germany" = "de",
    "france" = "fr",
    "china" = "cn",
    "japan" = "jp",
    "india" = "in",
    "brazil" = "br",
    "russia" = "ru", "russian federation" = "ru",
    "australia" = "au",
    "south korea" = "kr", "korea, republic of" = "kr", "korea, rep." = "kr",
    "north korea" = "kp", "korea, democratic" = "kp", "korea, dem. people's rep." = "kp",
    "mexico" = "mx",
    "italy" = "it",
    "spain" = "es",
    "netherlands" = "nl",
    "sweden" = "se",
    "norway" = "no",
    "denmark" = "dk",
    "finland" = "fi",
    "switzerland" = "ch",
    "austria" = "at",
    "belgium" = "be",
    "poland" = "pl",
    "czech republic" = "cz",
    "hungary" = "hu",
    "portugal" = "pt",
    "greece" = "gr",
    "turkey" = "tr", "turkiye" = "tr",
    "israel" = "il",
    "saudi arabia" = "sa",
    "united arab emirates" = "ae",
    "egypt" = "eg",
    "south africa" = "za",
    "nigeria" = "ng",
    "kenya" = "ke",
    "ethiopia" = "et",
    "ghana" = "gh",
    "morocco" = "ma",
    "tunisia" = "tn",
    "algeria" = "dz",
    "libya" = "ly",
    "sudan" = "sd",
    "somalia" = "so",
    "yemen" = "ye",
    "iraq" = "iq",
    "iran" = "ir", "iran, islamic rep." = "ir",
    "afghanistan" = "af",
    "pakistan" = "pk",
    "bangladesh" = "bd",
    "sri lanka" = "lk",
    "nepal" = "np",
    "bhutan" = "bt",
    "maldives" = "mv",
    "myanmar" = "mm", "burma" = "mm",
    "thailand" = "th",
    "vietnam" = "vn", "viet nam" = "vn",
    "laos" = "la", "lao pdr" = "la",
    "cambodia" = "kh",
    "malaysia" = "my",
    "singapore" = "sg",
    "indonesia" = "id",
    "philippines" = "ph",
    "taiwan" = "tw", "taiwan, china" = "tw",
    "mongolia" = "mn",
    "new zealand" = "nz",
    "fiji" = "fj",
    "papua new guinea" = "pg",
    "argentina" = "ar",
    "chile" = "cl",
    "colombia" = "co",
    "peru" = "pe",
    "venezuela" = "ve", "venezuela, rb" = "ve",
    "ecuador" = "ec",
    "bolivia" = "bo",
    "paraguay" = "py",
    "uruguay" = "uy",
    "guyana" = "gy",
    "suriname" = "sr",
    "haiti" = "ht",
    "dominican republic" = "do",
    "cuba" = "cu",
    "jamaica" = "jm",
    "trinidad and tobago" = "tt",
    "barbados" = "bb",
    "belize" = "bz",
    "costa rica" = "cr",
    "panama" = "pa",
    "nicaragua" = "ni",
    "honduras" = "hn",
    "el salvador" = "sv",
    "guatemala" = "gt",
    "bahamas" = "bs",
    "democratic republic of the congo" = "cd", "drc" = "cd", "congo, dem. rep." = "cd",
    "congo" = "cg", "republic of the congo" = "cg", "congo, rep." = "cg",
    "tanzania" = "tz", "united republic of tanzania" = "tz",
    "uganda" = "ug",
    "rwanda" = "rw",
    "burundi" = "bi",
    "madagascar" = "mg",
    "mozambique" = "mz",
    "zimbabwe" = "zw",
    "zambia" = "zm",
    "malawi" = "mw",
    "angola" = "ao",
    "cameroon" = "cm",
    "senegal" = "sn",
    "mali" = "ml",
    "burkina faso" = "bf",
    "niger" = "ne",
    "chad" = "td",
    "central african republic" = "cf",
    "south sudan" = "ss",
    "eritrea" = "er",
    "djibouti" = "dj",
    "mauritania" = "mr",
    "gambia" = "gm", "the gambia" = "gm", "gambia, the" = "gm",
    "guinea" = "gn",
    "sierra leone" = "sl",
    "liberia" = "lr",
    "togo" = "tg",
    "benin" = "bj",
    "ivory coast" = "ci", "cote divoire" = "ci", "côte divoire" = "ci", "cote d'ivoire" = "ci"
  )

  if (country_lower %in% names(country_codes)) {
    return(country_codes[[country_lower]])
  }

  for (code_name in names(country_codes)) {
    if (grepl(code_name, country_lower, fixed = TRUE)) {
      return(country_codes[[code_name]])
    }
  }

  "un"
}

.iso3_to_flag2_lookup <- local({
  path <- file.path("data", "metadata", "iso3_to_flag2.csv")
  if (!file.exists(path)) return(character())
  df <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (!all(c("iso3c", "iso2c") %in% names(df))) return(character())
  stats::setNames(tolower(trimws(df$iso2c)), toupper(trimws(df$iso3c)))
})

profile_country_flag_code <- function(country_name, iso3c = NA_character_) {
  code <- get_country_flag_code(country_name)
  if (!identical(code, "un")) return(code)
  if (is.na(iso3c) || !nzchar(iso3c)) return(code)
  ic <- toupper(trimws(iso3c))
  lookup <- .iso3_to_flag2_lookup
  if (length(lookup) && !is.na(lookup[[ic]])) return(lookup[[ic]])
  code
}

country_flag_img_url <- function(flag_code, width = 160L) {
  paste0("https://flagcdn.com/w", width, "/", flag_code, ".png")
}
