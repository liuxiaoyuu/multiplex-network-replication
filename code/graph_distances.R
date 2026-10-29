# Maximum finite geodesic distance and component count by unweighted BFS.
# Isolated vertices have eccentricity zero. Input must be symmetric, binary, no loops.
finite_graph_distances <- function(A) {
  stopifnot(isSymmetric(A),all(A %in% 0:1),all(diag(A)==0))
  n<-nrow(A);neighbors<-lapply(seq_len(n),function(i)which(A[,i]>0))
  component<-integer(n);ncomp<-0L;diam<-0L
  for(s in seq_len(n)) {
    unseen<-rep(TRUE,n);unseen[s]<-FALSE;front<-s;ecc<-0L
    repeat {
      nextfront<-unique(unlist(neighbors[front],use.names=FALSE))
      nextfront<-nextfront[unseen[nextfront]]
      if(!length(nextfront))break
      unseen[nextfront]<-FALSE;front<-nextfront;ecc<-ecc+1L
    }
    diam<-max(diam,ecc)
    if(component[s]==0L){ncomp<-ncomp+1L;component[!unseen]<-ncomp}
  }
  list(diameter=diam,components=ncomp)
}
