% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/range.calculations.tree.wide.R
\name{three.timer.rates}
\alias{three.timer.rates}
\title{Calculate speciation and extinction rates using the three-timer approach for a set of equal length intervals}
\usage{
three.timer.rates(fossils, max.age, strata, continuous = TRUE,
  return.intervals = FALSE)
}
\arguments{
\item{fossils}{Dataframe of sampled fossils (sp = unique species ID. h = ages.)}

\item{strata}{Number of stratigraphic intervals}

\item{continuous}{If TRUE calculate continuous rates (i.e. account for interval length)}

\item{return.intervals}{If TRUE return per interval estimates}

\item{basin.age}{Maximum age of the oldest stratigraphic interval}
}
\value{
named list with the overall speciation rate, overall extinction rate, overall sampling rate and a dataframe of per interval estimtes if return.intervals = TRUE.
Note this approach does not return rates for the first interval.
}
\description{
By default the function returns tree-wide estimates of speciation and extinction rates,
which are calculated by summing taxon counts across all intervals.
This approach relies on having equal length intervals.
}
\details{
The overall sampling probability Ps = 3t / (3t + Pt), where 3t and Pt are summed across the entire dataset \cr
The per-interval speciation rate lamda = log(2ti+1/3t) + log(Ps) \cr
The per-interval extinction rate mu = log(2ti/3t) + log(Ps) \cr
}
\examples{
# simulate tree & fossils
t = TreeSim::sim.bd.taxa(100,1,1,0.1)[[1]]
# budding speciation
sp = FossilSim::sim.taxonomy(t)
# simulate fossils
max = FossilSim::tree.max(t)
f = FossilSim::sim.fossils.intervals(taxonomy = sp, max.age = max, strata = 10, probabilities = rep(0.5,10), use.exact.times = FALSE)
# add extant occurrences
f = FossilSim::sim.extant.samples(f, taxonomy = sp)
# calculate speciation and extinction rates
three.timer.rates(f, max, 10)
}
\references{
Alroy, J et al. 2008. Dynamics of origination and extinction in the marine fossil record. PNAS 105: 11536-11542. \cr
Alroy, J 2014. Accurate and precise estimates of origination and extinction rates. Paleobiology 40: 374-397.
}
