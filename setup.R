# Run from the project root. renv is bootstrapped by .Rprofile.
if(!requireNamespace("renv",quietly=TRUE))stop("Use the release .Rprofile, which activates renv.")
renv::restore(library=renv::paths$library(),prompt=FALSE)
