% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/realFisheryAgecomp.r
\docType{data}
\name{realFisheryAgecomp}
\alias{realFisheryAgecomp}
\title{Fishery Age composition for the mskeyrun project based on catch data}
\format{
A data frame

\describe{
\item{ModSim}{Atlantis model name and simulation id, or Actual data}
\item{year}{year of catch}
\item{Code}{Species itis code}
\item{Name}{Common name for species}
\item{fishery}{fishery name}
\item{age}{age of fish in fishery, yrs}
\item{variable}{metric recorded, Number at age}
\item{value}{value of the variable}
\item{units}{units of the variable}

}
}
\usage{
realFisheryAgecomp
}
\description{
Data pulled from the NEFSC commercial fishery database. Methods to obtain
catch at age compositions are described in \code{\link{mscatch}} package
}
\keyword{datasets}
