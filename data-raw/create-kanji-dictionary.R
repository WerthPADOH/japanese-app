# Download and prepare the kanji dictionary
# Files and information taken from the Electronic Dictionary Research and
# Development Group wiki
# http://www.edrdg.org/wiki/index.php/KANJIDIC_Project
library(xml2)
library(magrittr)
library(data.table)
library(stringi)


source("data-raw/utilities.R")

# Download needed files ----
dic_url <- "http://www.edrdg.org/kanjidic/kanjidic2.xml.gz"
dic_local <- file.path("data-raw", basename(dic_url))
download.file(dic_url, dic_local)
dic_xml <- read_xml(dic_local)

# Main table ----
kanji_nodes <- xml_find_all(dic_xml, "character")
misc_nodes <- xml_find_first(kanji_nodes, "misc")

kanji <- data.table(
  kanji_id = seq_along(kanji_nodes),
  char = kanji_nodes %>%
    xml_find_first("literal") %>%
    xml_text(),
  utf8_code = kanji_nodes %>%
    xml_find_first("codepoint/cp_value[@cp_type = 'ucs']") %>%
    xml_text(),
  strokes = misc_nodes %>%
    xml_find_first("stroke_count") %>%
    xml_text() %>%
    as.integer(),
  grade = misc_nodes %>%
    xml_find_first("grade") %>%
    xml_text() %>%
    as.integer(),
  jlpt = misc_nodes %>%
    xml_find_first("jlpt") %>%
    xml_text() %>%
    factor(levels = 1:4, labels = c("N1", "N2/N3", "N4", "N5"), ordered = TRUE),
  news_frequency = misc_nodes %>%
    xml_find_first("freq") %>%
    xml_text() %>%
    as.integer()
)

# Variants table ----
codepoint_nodes <- xml_find_all(kanji_nodes, "codepoint/cp_value")
codepoints <- data.table(
  variant_id = match_ancestor(codepoint_nodes, kanji_nodes),
  type = xml_attr(codepoint_nodes, "cp_type"),
  code = xml_text(codepoint_nodes)
)

variant_nodes <- xml_find_all(misc_nodes, "variant")
variants <- data.table(
  kanji_id = match_ancestor(variant_nodes, kanji_nodes),
  type = xml_attr(variant_nodes, "var_type"),
  code = xml_text(variant_nodes)
)[
  codepoints,
  on = c("type", "code"),
  variant_id := variant_id
]

# Reading/meaning table ----
reading_nodes <- xml_find_all(kanji_nodes, "reading_meaning/rmgroup")
jp_on_nodes <- xml_find_all(reading_nodes, "reading[@r_type = 'ja_on']")
jp_kun_nodes <- xml_find_all(reading_nodes, "reading[@r_type = 'ja_kun']")

readings <- data.table(
  kanji_id = c(
    match_ancestor(jp_on_nodes, kanji_nodes),
    match_ancestor(jp_kun_nodes, kanji_nodes)
  ),
  type = rep(c("on", "kun"), c(length(jp_on_nodes), length(jp_kun_nodes))),
  read = c(xml_text(jp_on_nodes), xml_text(jp_kun_nodes))
)

meaning_nodes <- xml_find_all(reading_nodes, "meaning[not(@m_lang)]")
meanings <- data.table(
  kanji_id = match_ancestor(meaning_nodes, kanji_nodes),
  meaning = xml_text(meaning_nodes)
)

# Save needed tables for the app ----
save(kanji, variants, readings, meanings, file = "data/kanji-tables.RData")
