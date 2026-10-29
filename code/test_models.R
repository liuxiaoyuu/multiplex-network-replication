# Data-free numerical tests. Empirical equivalence checks also run in run.py.
source('code/predictive_models.R');source('code/count_models.R')
source('code/graph_distances.R')
# Disconnected path, triangle, and isolate: finite diameter is 3, components 3.
A<-matrix(0,8,8)
for(e in list(c(1,2),c(2,3),c(3,4),c(5,6),c(6,7),c(5,7))){A[e[1],e[2]]<-1;A[e[2],e[1]]<-1}
stopifnot(identical(finite_graph_distances(A),list(diameter=3L,components=3L)))
set.seed(412)
d<-data.frame(dummy_3_seeds=rep(0:1,20),num_hh_random=runif(40,70,300),sum_advice=rnorm(40))
d$CallsReceived<-rpois(40,d$num_hh_random*exp(-3+.2*d$sum_advice))
tr<-d[1:32,];te<-d[33:40,];des<-count_design(tr,te,'sum_advice')
fit<-count_predict(tr,te,'sum_advice',.1);alt<-count_predict(tr,te,'sum_advice',.1,TRUE)
stopifnot(fit$converged,max(abs(fit$predicted-alt$predicted))<1e-3)
# Intercept/seed coefficients are unpenalized: constant exposure rescales the intercept only.
tr2<-tr;te2<-te;tr2$num_hh_random<-2*tr2$num_hh_random;te2$num_hh_random<-2*te2$num_hh_random
stopifnot(max(abs(fit$predicted-count_predict(tr2,te2,'sum_advice',.1)$predicted))<1e-6)
te$CallsReceived<-te$CallsReceived+100000
stopifnot(identical(fit$predicted,count_predict(tr,te,'sum_advice',.1)$predicted))
stopifnot(max(abs(poisson_deviance(c(0,1,3),c(2,1,3))-c(4,0,0)))<1e-12)
cat('Poisson optimization, exposure equivariance, held-out isolation and deviance tests PASS.\n')
