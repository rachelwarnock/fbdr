% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fbd.calculations.R
\name{recount.gamma}
\alias{recount.gamma}
\alias{recount.extant}
\alias{fbd.probability}
\title{FBD probability}
\usage{
recount.gamma(frs)

recount.extant(frs)

fbd.probability(frs, b, d, s, k, rho = 1, complete = F, mpfr = F)
}
\arguments{
\item{frs}{Dataframe of species ranges}

\item{b}{Rate of speciation}

\item{d}{Rate of extinction}

\item{s}{Rate of sampling}

\item{k}{Number of fossils}
}
\value{
Log likelihood
}
\description{
Calculate the probabilty of speciaton, extinction and sampling rates for a given set of stratigraphic ranges
}
\examples{
# simulate tree & fossils
birth = 1
death = 0.1
t = TreeSim::sim.bd.taxa(100, 1, birth, death)[[1]]
psi = 1
f = FossilSim::sim.fossils.poisson(tree = t, psi)
k = length(f$sp)
# add extant occurrences
f = FossilSim::sim.extant.samples(f, t)
# calculate range attachment times given incomplete sampling
frs = attachment.times(t, f)
# rename range data headers
names(frs)[2]<-"bi"
names(frs)[3]<-"di"
names(frs)[4]<-"oi"
frs = recount.extant(frs)
frs = recount.gamma(frs)
fbd.probability(frs, birth, death, psi, k)
}
