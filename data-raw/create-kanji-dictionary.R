# Download and prepare the kanji dictionary
# Files and information taken from the Electronic Dictionary Research and
# Development Group wiki
# http://www.edrdg.org/wiki/index.php/KANJIDIC_Project
# The file of radicals in kanji is from the Monash University FTP server
# http://www.edrdg.org/krad/kradinf.html
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

krad_url <- "ftp://ftp.monash.edu/pub/nihongo/kradzip.zip"
krad_local <- file.path("data-raw", basename(krad_url))
download.file(krad_url, krad_local)
unzip(krad_local, exdir = "data-raw")
krad1 <- readLines("data-raw/kradfile", encoding = "UTF-8")

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

# Radicals ----

radical_nodes <- xml_find_all(kanji_nodes, "radical/rad_value")
radicals <- data.table(
  radical_id = seq_along(radical_nodes),
  type = xml_attr(radical_nodes, "rad_type"),
  value = xml_text(radical_nodes)
)
