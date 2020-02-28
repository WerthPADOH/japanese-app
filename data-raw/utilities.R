# Utility functions used to create the dictionaries
match_ancestor <- function(x, ancestors) {
  ancestor_name <- xml2::xml_name(ancestors[[1]])
  xpath <- paste0("ancestor::", ancestor_name)
  found <- xml2::xml_find_first(x, xpath)
  match(found, ancestors)
}
