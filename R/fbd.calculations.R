

#' @export
#' @rdname fbd.probability
recount.gamma<-function(frs){

  ot=max(frs$bi)

  for(f in 1:length(frs$bi)){
    bf=frs$bi[f]
    df=frs$di[f]
    g=0
    for(j in 1:length(frs$bi)){
      bj=frs$bi[j]
      dj=frs$di[j]

      if( (bj > bf) & (dj < bf) )
        g=g+1
    }
    if(bf==ot)
      g=g+1

    frs$gamma[f]=g
  }
  #fossilRanges <<- frs
  return(frs)
  #eof
}


#' @export
#' @rdname fbd.probability
recount.extant<-function(frs){

  for(f in 1:length(frs$bi)){
    df=frs$di[f]

    if(df==0)
      frs$extant[f]=1
    else
      frs$extant[f]=0
  }
  #fossilRanges <<- frs
  return(frs)
  #eof
}

#### probability functions

#' FBD probability
#'
#' Calculate the probabilty of speciaton, extinction and sampling rates for a given set of stratigraphic ranges
#'
#' @param frs Dataframe of species ranges
#' @param b Rate of speciation
#' @param d Rate of extinction
#' @param s Rate of sampling
#' @param k Number of fossils
#' @return Log likelihood
#'
#' @examples
#' # simulate tree & fossils
#' birth = 1
#' death = 0.1
#' t = TreeSim::sim.bd.taxa(100, 1, birth, death)[[1]]
#' psi = 1
#' f = FossilSim::sim.fossils.poisson(tree = t, psi)
#' k = length(f$sp)
#' # add extant occurrences
#' f = FossilSim::sim.extant.samples(f, t)
#' # calculate range attachment times given incomplete sampling
#' frs = attachment.times(t, f)
#' # rename range data headers
#' names(frs)[2]<-"bi"
#' names(frs)[3]<-"di"
#' names(frs)[4]<-"oi"
#' frs = recount.extant(frs)
#' frs = recount.gamma(frs)
#' fbd.probability(frs, birth, death, psi, k)
#' @export
fbd.probability<-function(frs,b,d,s,k,rho=1,complete=F,mpfr=F){

  bits = 128
  if(mpfr){
    lambda<<-mpfr(b, bits)
    mu<<-mpfr(d, bits)
    psi<<-mpfr(s, bits)
    rho<<-mpfr(rho, bits)
  }
  else{
    lambda<<-b
    mu<<-d
    psi<<-s
    rho<<-rho
  }

  ot = max(frs$bi) # define the origin
  extinctLineages = length(frs$extant) - sum(frs$extant)

  pr = numFossils*log(psi)
  pr = pr + extinctLineages*log(mu)
  pr = pr - log(lambda * (1 - fbdPfxn(ot) ) )

  # for complete sampling (b_i = o_i)
  if(!mpfr){
    if(complete)
      rp = sum(unlist(lapply(1:length(frs$bi),function(x){ rangePrComplete(frs$gamma[x],frs$bi[x],frs$di[x]) })))
    else
      rp = sum(unlist(lapply(1:length(frs$bi),function(x){ rangePr(frs$gamma[x],frs$bi[x],frs$di[x],frs$oi[x]) })))
  }
  else {
    rp.all = lapply(1:length(frs$bi),function(x){ rangePr(frs$gamma[x],frs$bi[x],frs$di[x],frs$oi[x]) })
    rp = 0
    for(i in 1:length(rp.all)){
      rp = rp + rp.all[[i]]
    }
  }

  pr = pr + rp
  return(pr)

}

fbdC1fxn<-function(){

  c1 = abs ( sqrt( (lambda - mu - psi)^2 + (4*lambda*psi) ) )

  return(c1)
}

fbdC2fxn<-function(){

  c1 = fbdC1fxn()
  c2 = -(lambda - mu - (2*lambda*rho) - psi ) / c1

  return(c2)

}

fbdC3fxn<-function(){

  c3 = lambda * (-psi+rho*(mu+lambda*(-1+rho)+psi))

  return(c3)

}

fbdC4fxn<-function(){

  c1 = fbdC1fxn()
  c3 = fbdC3fxn()

  c4 = c3/(c1^2)

  return(c4)
}

fbdPfxn<-function(t){

  c1 = fbdC1fxn()
  c2 = fbdC2fxn()

  p = ( ((lambda+mu+psi) +  (c1 * ( ( exp(-c1*t)*(1-c2)/(1+c2) - 1 ) / ( exp(-c1*t)*(1-c2)/(1+c2) + 1 ) ) ) ) / (2*lambda) )

  return(p)
}

# rho = 1
fbdQTildaFxnLog<-function(t){

  c1 = fbdC1fxn()
  c2 = fbdC2fxn()
  c4 = fbdC4fxn()

  f1aLog = -t*(lambda+mu+psi+c1) #log f1a
  f1b = c4 * (1-exp(-t*c1))^2 - exp(-t*c1)
  f2a = ((1-c2) * (2*c4*(exp(-t*c1)-1))+exp(-t*c1)*(1-c2^2))
  f2b = ((1+c2) * (2*c4*(exp(-t*c1)-1))+exp(-t*c1)*(1-c2^2))

  f = f1aLog + log(-1/f1b * (f2a/f2b) )

  q = 0.5*f + log(rho)

  return(q)
}

fbdQfxnLog<-function(t){

  c1 = fbdC1fxn()
  c2 = fbdC2fxn()

  f1 = log(4) + (-c1 * t)
  f2 = 2 * (log( (exp(-c1*t) * (1-c2)) + (1+c2) ))

  v = f1 - f2;

  return(v)
}

rangePrComplete<-function(gamma,bi,di){

  rp = log(lambda*gamma) + fbdQTildaFxnLog(bi) - fbdQTildaFxnLog(di)

  return(rp)

}

rangePr<-function(gamma,bi,di,oi){

  rp = log(lambda*gamma) + fbdQTildaFxnLog(oi) - fbdQTildaFxnLog(di) + fbdQfxnLog(bi) - fbdQfxnLog(oi)

  return(rp)

}

qt_heath<-function(t){

  c1=fbdC1fxn()
  c2=fbdC2fxn()

  v1 = 2 * ( 1 - c2^2 )
  v2 = exp(-c1 * t) * ((1 - c2)^2)
  v3 = exp(c1 * t) * ((1 + c2)^2)

  v = v1 + v2 + v3

  return(v)
}

# rho < 1
fbdQTildaFxnLogAlt<-function(t){

  c1 = fbdC1fxn()
  c2 = fbdC2fxn()

  f1aLog = log(4) + (-t * c1) + (-t * (lambda + mu + psi) )
  f1b = 4 * exp(-t * c1) + (1 - c2*c2) * (1 - exp(-t * c1)) * (1 - exp(-t * c1))

  f2a = (1 + c2) * exp(-t * c1) + (1 - c2)
  f2b = (1 - c2) * exp(-t * c1) + (1 + c2)

  qt = 0.5 * (log( (1/f1b) * (f2a/f2b)  ) + (f1aLog))

  return(qt)
}



