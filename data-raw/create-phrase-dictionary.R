# Download and prepare the Japanese/English dictionary
# Files from the Monash University FTP server
# Information about the files taken from the Electronic Dictionary Research and
# Development Group wiki
# http://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project
library(xml2)
library(magrittr)
library(data.table)


source("data-raw/utilities.R")

dic_url <- "http://ftp.monash.edu/pub/nihongo/JMdict_e.gz"
dic_local <- file.path("data-raw", basename(dic_url))
download.file(dic_url, dic_local)
dic_xml <- read_xml(dic_local)


entry_nodes <- xml_children(dic_xml)

# Writing information ----
kanji_nodes <- xml_find_all(entry_nodes, "k_ele")

kanji <- data.table(
  entry_id = match_ancestor(kanji_nodes, entry_nodes),
  kanji_id = seq_along(kanji_nodes),
  phrase = xml_find_first(kanji_nodes, "keb") %>% xml_text()
)
setkeyv(kanji, "kanji_id")
setindexv(readings, "entry_id")

# Reading information ----
reading_nodes <- xml_find_all(entry_nodes, "r_ele")

readings <- data.table(
  entry_id = match_ancestor(reading_nodes, entry_nodes),
  reading_id = seq_along(reading_nodes),
  reading = xml_find_first(reading_nodes, "reb") %>% xml_text()
)
setkeyv(readings, "reading_id")
setindexv(readings, "entry_id")

readings[
  ,
  true_reading := reading_nodes[reading_id] %>%
    xml_find_first("re_nokanji") %>%
    vapply(is.na, logical(1))
]

reading_info_nodes <- xml_find_all(reading_nodes, "re_inf")
reading_info <- data.table(
  reading_id = match_ancestor(reading_info_nodes, reading_nodes),
  info = xml_text(reading_info_nodes)
)

restrict_nodes <- xml_find_all(reading_nodes, "re_restr")
reading_restrictions <- data.table(
  reading_id = match_ancestor(restrict_nodes, reading_nodes),
  phrase = xml_text(restrict_nodes)
)[
  readings,
  on = "reading_id",
  entry_id := entry_id
][
  kanji,
  on = c("entry_id", "phrase"),
  kanji_id := kanji_id
]

# Grammar/translation information ----
