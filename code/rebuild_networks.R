# Independent reconstruction, using raw adjacency matrices and node/caste/seed keys.
# Environment is configured by the project .Rprofile.
suppressPackageStartupMessages(library(haven))
source('code/graph_distances.R')
t0<-proc.time()[['elapsed']]
p<-'private_inputs/'
raw<-R.matlab::readMat(paste0(p,'rct_network_adjacency_layers.mat'))[[1]]
keys<-R.matlab::readMat(paste0(p,'rct_hh_vertex_crosswalk.mat'))[[1]]
hh<-as.data.frame(read_dta(paste0(p,'rct_hh_covariates.dta')))
ref<-read.csv(paste0(p,'rct_village_seed_diffusion_centrality.csv'))
refmat<-new.env();load(paste0(p,'rct_network_adjacency_layers.RData'),envir=refmat)
refjati<-readRDS(paste0(p,'rct_hh_pair_jati_layer.rds'))
rows<-list();rebuild<-list();audit<-list()
for(v in ref$village){
 raw_layers<-lapply(seq_len(6),function(j)as.matrix(raw[[v]][[1]][[j]][[1]]))
 n<-nrow(raw_layers[[1]])
 stopifnot(all(vapply(raw_layers,function(a)nrow(a)==n && ncol(a)==n && !anyNA(a) && all(a %in% 0:1),logical(1))))
 sy<-lapply(raw_layers,function(a){b<-(a+t(a)>0)*1;diag(b)<-0;b})
 k<-keys[[v]][[1]];stopifnot(nrow(k)==n,all(k[,1]==seq_len(n)),!anyDuplicated(k[,2]))
 hv<-hh[hh$villageid==v,];stopifnot(!anyNA(hv$vertex),!anyDuplicated(hv$vertex),all(hv$vertex %in% k[,1]))
 stopifnot(all(k[match(hv$vertex,k[,1]),2]==hv$hhid))
 cv<-read.delim(paste0(p,'covariates_',v,'.csv'),quote='',stringsAsFactors=FALSE)
 stopifnot(!anyDuplicated(cv$hh_id));jati<-cv$subcaste[match(k[,2],cv$hh_id)]
 stopifnot(!anyNA(jati));jati[jati %in% c(-888,-666,-333)]<- -966
 J<-outer(jati,jati,'==')*1;J[jati== -966,]<-0;J[,jati== -966]<-0;diag(J)<-0
 layers<-list(social=(sy[[3]]+sy[[4]]>0)*1,kerorice=(sy[[1]]+sy[[2]]>0)*1,advice=sy[[6]],decision=sy[[5]],jati=J)
 layers$union_link<-(Reduce('+',layers)>0)*1
 layers$intersect_link<-Reduce('*',layers)
 layers$raw_wtd<-Reduce('+',raw_layers);diag(layers$raw_wtd)<-0
 seeds<-hv$vertex[!is.na(hv$seed_dummy) & hv$seed_dummy==1]
 r<-data.frame(village=v)
 for(name in names(layers)){
  A<-layers[[name]];is_sym<-isSymmetric(A)
  author_A<-if(name=='jati')refjati[[v]] else refmat[[name]][[v]]
  stopifnot(identical(dim(A),dim(author_A)),max(abs(A-author_A))==0)
  lambda<-max(Mod(eigen(A,symmetric=is_sym,only.values=TRUE)$values));stopifnot(lambda>0)
  graph<-finite_graph_distances((A+t(A)>0)*1)
  T<-graph$diameter
  # Author code explicitly includes the identity (t=0) term. No giant-component restriction.
  step<-rep(1,n);DC<-step
  for(i in seq_len(T)){step<-drop(A%*%step)/lambda;DC<-DC+step}
  est<-if(v==62)NA_real_ else sum(DC[seeds])
  target<-ref[ref$village==v,paste0('sum_',name)]
  ok<-if(v==62)is.na(target) else abs(est-target)<=1e-7*max(1,abs(target))
  rows[[length(rows)+1L]]<-data.frame(village=v,layer=name,n=n,seeds=length(seeds),components=graph$components,T=T,q=1/lambda,reconstructed=est,author=target,abs_difference=abs(est-target),matches=ok,adjacency_exact=TRUE)
  r[[paste0('sum_',name)]]<-est
 }
 rebuild[[length(rebuild)+1L]]<-r
 audit[[length(audit)+1L]]<-data.frame(village=v,n=n,key_matches=TRUE,seed_count=length(seeds),missing_hh_rows=n-nrow(hv),missing_seed_flags=sum(is.na(hv$seed_dummy)),jati_missing_code=sum(jati== -966))
}
a<-do.call(rbind,rows);write.csv(a,'results/network_reconstruction.csv',row.names=FALSE)
write.csv(do.call(rbind,rebuild),'results/rebuilt_seed_centrality.csv',row.names=FALSE)
write.csv(do.call(rbind,audit),'results/node_seed_audit.csv',row.names=FALSE)
stopifnot(all(a$matches),all(a$adjacency_exact))
jsonlite::write_json(list(date='2026-10-28',status='PASS',villages=length(rebuild),layers=8,comparisons=nrow(a),nonmissing_DC=sum(!is.na(a$reconstructed)),max_absolute_difference=max(a$abs_difference,na.rm=TRUE),runtime_seconds=proc.time()[['elapsed']]-t0,scope='Eight layers reconstructed; backbone remains author-derived. No giant-component restriction in DC.'),'results/network_summary.json',pretty=TRUE,auto_unbox=TRUE)
cat('Rebuilt',nrow(a),'village-layer networks; all adjacency matrices and centralities pass.\n');print(aggregate(abs_difference~layer,a,max))
