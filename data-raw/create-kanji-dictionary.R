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
kanji <- data.table(
  kanji_id = seq_along(kanji_nodes),
  utf8_code = xml_find_all(kanji_nodes, "codepoint/cp_value[@cp_type = 'ucs']"),
  strokes = xml_find_first(kanji_nodes, "misc/stroke_count") %>%
    xml_text() %>%
    as.integer()
)

utf8_nodes <- xml_find_all(kanji_nodes, "codepoint/cp_value[@cp_type = 'ucs']")


