# README figure: one village drawn through each rebuilt relationship layer.
# Descriptive only; layer definitions follow rebuild_networks.R.
suppressPackageStartupMessages({library(haven);library(ggplot2)})
village<-2L
p<-'private_inputs/'
raw<-R.matlab::readMat(paste0(p,'rct_network_adjacency_layers.mat'))[[1]]
keys<-R.matlab::readMat(paste0(p,'rct_hh_vertex_crosswalk.mat'))[[1]]
hh<-as.data.frame(read_dta(paste0(p,'rct_hh_covariates.dta')))
raw_layers<-lapply(seq_len(6),function(j)as.matrix(raw[[village]][[1]][[j]][[1]]))
sy<-lapply(raw_layers,function(a){b<-(a+t(a)>0)*1;diag(b)<-0;b})
k<-keys[[village]][[1]]
cv<-read.delim(paste0(p,'covariates_',village,'.csv'),quote='',stringsAsFactors=FALSE)
jati<-cv$subcaste[match(k[,2],cv$hh_id)];stopifnot(!anyNA(jati))
jati[jati %in% c(-888,-666,-333)]<- -966
J<-outer(jati,jati,'==')*1;J[jati== -966,]<-0;J[,jati== -966]<-0;diag(J)<-0
observed<-list(social=(sy[[3]]+sy[[4]]>0)*1,kerorice=(sy[[1]]+sy[[2]]>0)*1,advice=sy[[6]],decision=sy[[5]])
# Overlap weight = number of the four observed layers containing the tie.
overlap<-Reduce('+',observed)
layers<-c(observed,list(jati=J,overlap=overlap))
# The plotted layers must equal those used in the analysis.
refmat<-new.env();load(paste0(p,'rct_network_adjacency_layers.RData'),envir=refmat)
for(name in names(observed))stopifnot(max(abs(observed[[name]]-refmat[[name]][[village]]))==0)
stopifnot(max(abs(J-readRDS(paste0(p,'rct_hh_pair_jati_layer.rds'))[[village]]))==0)
hv<-hh[hh$villageid==village,]
seeds<-hv$vertex[!is.na(hv$seed_dummy) & hv$seed_dummy==1]
n<-nrow(overlap)

# Base-R Fruchterman-Reingold on the union of the observed layers (no igraph dependency).
fr_layout<-function(A,niter=500L,seed=20261028L){
 set.seed(seed)
 xy<-cbind(runif(n,-1,1),runif(n,-1,1));kk<-sqrt(1/n);temp<-.1
 for(iter in seq_len(niter)){
  dx<-outer(xy[,1],xy[,1],'-');dy<-outer(xy[,2],xy[,2],'-')
  dist<-sqrt(dx^2+dy^2)+1e-6
  # Repulsion k^2/d between all pairs; attraction d^2/k along ties (both per unit direction).
  force<-kk^2/dist^2-A*dist/kk;diag(force)<-0
  disp<-cbind(rowSums(dx*force),rowSums(dy*force))
  len<-sqrt(rowSums(disp^2))+1e-6
  xy<-xy+disp/len*pmin(len,temp);temp<-temp*.985
 }
 # Scale to the connected households; isolates drift far under pure repulsion, so cap their radius.
 connected<-rowSums(A)>0
 xy<-sweep(xy,2,colMeans(xy[connected,,drop=FALSE]))
 r<-sqrt(rowSums(xy^2));xy<-xy/quantile(r[connected],.95)
 r<-sqrt(rowSums(xy^2));far<-r>1.6
 xy[far,]<-xy[far,,drop=FALSE]/r[far]*1.6
 xy
}
xy<-fr_layout((overlap>0)*1)

titles<-c(social='Social visits',kerorice='Material exchange',advice='Advice',decision='Decision help',jati='Same-jati proxy',overlap='Overlap of four observed layers')
colours<-c(social='#7d9fbd',kerorice='#86ab8f',advice='#d9a25f',decision='#bb93c7',jati='#9db5b2',overlap='#3f5873')
alphas<-c(social=.5,kerorice=.5,advice=.5,decision=.5,jati=.12,overlap=.45)
label<-function(name){A<-(layers[[name]]>0)*1
 sprintf('%s\n%s ties | %d isolates',titles[[name]],format(sum(A)/2,big.mark=','),sum(rowSums(A)==0))}
levels<-vapply(names(layers),label,character(1))
edges<-do.call(rbind,lapply(names(layers),function(name){
 A<-layers[[name]];e<-which(A>0 & upper.tri(A),arr.ind=TRUE)
 data.frame(x=xy[e[,1],1],y=xy[e[,1],2],xend=xy[e[,2],1],yend=xy[e[,2],2],
  weight=A[e],layer=name,panel=levels[[name]])}))
nodes<-do.call(rbind,lapply(names(layers),function(name)
 data.frame(x=xy[,1],y=xy[,2],seed=seq_len(n) %in% seeds,panel=levels[[name]])))
edges$panel<-factor(edges$panel,levels=levels);nodes$panel<-factor(nodes$panel,levels=levels)
edges$alpha<-alphas[edges$layer];edges$width<-ifelse(edges$layer=='overlap',.1+.18*edges$weight,.2)

plot<-ggplot()+
 geom_segment(data=edges,aes(x,y,xend=xend,yend=yend,colour=layer,alpha=alpha,linewidth=width),show.legend=FALSE)+
 scale_colour_manual(values=colours)+scale_alpha_identity()+scale_linewidth_identity()+
 geom_point(data=subset(nodes,!seed),aes(x,y),size=1.4,colour='#6b7480')+
 geom_point(data=subset(nodes,seed),aes(x,y),size=3,shape=21,fill='#d1532f',colour='white',stroke=.6)+
 facet_wrap(~panel,ncol=3)+coord_equal()+
 labs(title='One village, multiple social networks',
  subtitle=sprintf('Village %d | %d household nodes | %d recorded seed households | identical node positions in every panel',village,n,length(seeds)),
  caption=paste('Orange nodes: recorded seed households. All nodes and ties are retained; no outcome-based selection.',
   'Same-jati ties are constructed from shared subcaste, not observed interaction. Thicker overlap ties occur in more layers.',
   'Layout uses the union of the four observed layers; positions are not geographical. Descriptive visualization, not an observed diffusion path.',sep='\n'))+
 theme_void(base_size=14)+
 theme(plot.title=element_text(face='bold',size=26,margin=margin(b=6)),plot.subtitle=element_text(colour='#56606b',margin=margin(b=18)),
  strip.text=element_text(face='bold',size=13,lineheight=1.25,margin=margin(b=8)),
  plot.caption=element_text(hjust=0,colour='#56606b',size=11,lineheight=1.4,margin=margin(t=16)),
  plot.margin=margin(28,40,24,40),panel.spacing=unit(2,'lines'))
ggsave('results/network_multiplex_village2.png',plot,width=14.3,height=11.33,dpi=200,bg='white')
cat('Wrote results/network_multiplex_village2.png:',n,'households,',length(seeds),'seeds\n')
