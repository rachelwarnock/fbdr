
#' Birth-death probability (Keiding, 1975)
#'
#' Calculate the probabilty of speciaton and extinction rates for a given set of stratigraphic ranges
#'
#' @param frs Dataframe of species ranges
#' @param b Rate of speciation
#' @param d Rate of extinction
#' @param crown If TRUE assume the process begins at the first speciation event and not the origin (default = FALSE)
#' @param tol rounding-error tolerance for extant taxa
#' @return Log likelihood
#'
#' @references
#' Keiding, N. 1975. Maximum likelihood estimation in the birth-death process. Annals of Statistics 3: 363-372.
#'
#' @examples
#' # simulate tree & assume complete sampling
#' t = TreeSim::sim.bd.taxa(100,1,1,0.1)[[1]]
#' # simulated mixed speciation
#' beta = 0.5
#' lambda.a = 0.1
#' frs <- FossilSim::sim.taxonomy(tree = t, beta = beta, lambda.a = 0.1)
#' # calculate birth-death probability
#' birth = 1
#' death = 0.1
#' bd.probability.range(frs, birth, death)
#' @export
bd.probability.range<-function(frs,b,d,crown=FALSE,tol=NULL){

  tmp = frs
  sp = unique(tmp$sp)
  frs = data.frame(sp = sp)

  frs$start = sapply(sp, function(x) { max(tmp$start[which(tmp$sp == x)]) })
  frs$end = sapply(sp, function(x) { min(tmp$end[which(tmp$sp == x)]) })

  if(is.null(tol)) tol = min((min(frs$start - frs$end)/100),1e-8)

  B = 0 # total number of speciation events # int
  D = 0 # total number of extinction events # int
  S = 0 # total lineage duration

  # condition on the crown, instead of the origin
  if(crown)
    B = length(frs$sp)
  else
    B = length(frs$sp)-1 # note the origin is not a speciation event

  D = length(which(frs$end > tol))
  S = sum(frs$start-frs$end)

  # also see Silvestro et al. 2014, eq. 9
  ll = (B * log(b)) + (D * log(d)) + (-(b + d) * S)

  return(ll)

}

#' Birth-death probability (Stadler, 2012)
#'
#' Probability of extant species phylogeny conditioned on the origin (Stadler, 2012, eq. 2)
#' or the crown (crown = T) (Stadler, 2012, eq. 5)
#'
#' @param tree Phylo object of extant taxa (the function will remove any extinct taxa prior to calculating the likelihood)
#' @param b Rate of speciation (branching)
#' @param d Rate of extinction (branch termination). Must be < b
#' @param rho Extant species sampling probability
#' @param crown If TRUE the process is conditioned on the crown (default = F)
#' @return Log likelihood
#'
#' @references
#' Stadler, T. 2012. How can we improve accuracy of macroevolutionary rate estimates? Systematic Biology 62: 321-329.
#'
#' @examples
#' # simulate tree
#' t = TreeSim::sim.bd.taxa(100,1,1,0.1)[[1]]
#' # calculate birth-death probability
#' birth = 1
#' death = 0.1
#' bd.probability.extant(t, birth, death)
#' @export
bd.probability.extant<-function(tree,b,d,rho=1,mpfr=FALSE,crown=FALSE){
  tree<-tree
  bits = 128
  if(mpfr){
    lambda<<-mpfr(b, bits)
    mu<<-mpfr(d, bits)
    rho<<-mpfr(rho, bits)
  }
  else{
    lambda = b
    mu = d
    rho = rho
  }
  crown = crown

  # bdP1 function Stadler 2010, 322
  bdP1<-function(t){
    t<-t

    p1 = rho * (lambda - mu)^2 * exp(-(lambda-mu)*t)
    p2 = p1 / (((rho * lambda) + (((lambda * (1 - rho)) - mu) * exp(-(lambda-mu)*t)))^2)

    return(p2)
  }

  bdP1Log<-function(t){
    t<-t

    p1 = log(rho) + (2 * log(lambda - mu) ) + (-(lambda-mu)*t)

    p2 = p1 - (2 * log((rho * lambda) + (((lambda * (1 - rho)) - mu) * exp(-(lambda-mu)*t))) )

    return(p2)
  }

  # bdP0 function Stadler 2010, 322 or Phat in Heath et al. 2014
  bdP0<-function(t){
    t<-t

    p = 1 - ( (rho * (lambda-mu)) / ((rho * lambda) + ((lambda*(1-rho)-mu)*exp(-(lambda-mu)*t)) ) )

    return(p)
  }

  # this doesn't work if 1-(b-d) < 0
  bdP0Log<-function(t){
    t<-t

    p = log(1 - (rho * (lambda-mu)) ) - log( ((rho * lambda) + ((lambda*(1-rho)-mu)*exp(-(lambda-mu)*t)) ) )

    return(p)
  }

  tree<-geiger::drop.extinct(tree)

  # calculate node ages
  node.ages = TreeSim::getx(tree)

  # equation 5
  if(crown){

    # take care of the crown
    c = max(node.ages)
    ll = 2 * ( bdP1Log(c) - log(1 - bdP0(c)) )

    # eliminate the root node
    node.ages = node.ages[-which(node.ages==c)]

  }
  else { # equation 2

    # take care of the origin
    origin = max(node.ages)+tree$root.edge
    ll = bdP1Log(origin) - log(1 - bdP0(origin))

  }

  for(i in node.ages){
    ll = ll + log(lambda) + bdP1Log(i)
  }

  return(ll)
}


