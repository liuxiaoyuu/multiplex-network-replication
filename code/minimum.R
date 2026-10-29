# Independently written minimum reproduction of Figure 2 / SI Table S2.
# Uses eight independently rebuilt measures and the author-derived PCA backbone.
t0 <- proc.time()[['elapsed']]
library(haven)
library(jsonlite)
dir.create('results',showWarnings=FALSE)
d <- as.data.frame(read_dta('private_inputs/rct_village_diffusion_outcomes.dta'))
c <- read.csv('private_inputs/rct_village_seed_diffusion_centrality.csv')
rebuilt <- read.csv('results/rebuilt_seed_centrality.csv')
stopifnot(setequal(c$village,rebuilt$village))
idx<-match(c$village,rebuilt$village)
for(nm in setdiff(names(rebuilt),'village'))c[[nm]]<-rebuilt[[nm]][idx]
# Eight layer columns above are independently rebuilt; backbone is still supplied.
stopifnot(!anyDuplicated(d$villageid[!is.na(d$villageid)]),!anyDuplicated(c$village))
d <- d[d$villageid %in% c(1:26,28:39,41:71),]
d$dummy_3_seeds <- as.numeric(d$num_seeds==3)
c <- c[match(d$villageid,c$village),]
stopifnot(all(d$villageid==c$village))
d <- cbind(d[c('villageid','CallsReceived','dummy_3_seeds','num_hh_random')],c[setdiff(names(c),c('village','sum_union_wtd'))])
d$num_hh_random_sq <- d$num_hh_random^2;d$num_hh_random_cb <- d$num_hh_random^3
scaled <- setdiff(names(d),c('villageid','CallsReceived','dummy_3_seeds'))
scaling <- data.frame(variable=scaled,mean=sapply(d[scaled],mean,na.rm=TRUE),sd=sapply(d[scaled],sd,na.rm=TRUE),n=sapply(d[scaled],function(x)sum(!is.na(x))))
write.csv(scaling,'results/standardization_audit.csv',row.names=FALSE)
d[scaled] <- lapply(d[scaled],function(x)as.numeric(scale(x)))
terms <- c('sum_social','sum_kerorice','sum_advice','sum_decision','sum_jati','sum_union_link','sum_intersect_link','sum_backbone','sum_raw_wtd')
target <- data.frame(term=terms,paper_beta=c(4.266,5.466,6.410,3.137,1.161,1.110,2.220,1.752,2.158),paper_SE=c(1.820,2.326,2.416,2.226,1.559,1.752,2.200,2.123,1.453),paper_p=c(.022,.022,.010,.164,.459,.529,.317,.412,.143),paper_R2=c(.194,.254,.313,.161,.110,.110,.139,.119,.131))
controls <- c('dummy_3_seeds','num_hh_random','num_hh_random_sq','num_hh_random_cb')
out <- lapply(seq_along(terms),function(i){
 term <- terms[i];ok <- complete.cases(d[c('CallsReceived',term,controls)]);dd<-d[ok,]
 f <- lm(reformulate(c(term,controls),'CallsReceived'),dd)
 X<-model.matrix(f);u<-resid(f);B<-solve(crossprod(X));h<-hatvalues(f)
 V<-B%*%crossprod(X*as.numeric(u/sqrt(1-h)))%*%B
 se<-sqrt(diag(V))[term];beta<-coef(f)[term];df<-df.residual(f)
 z<-data.frame(term=term,beta=unname(beta),HC2_SE=unname(se),p=unname(2*pt(-abs(beta/se),df)),R2=summary(f)$r.squared,N=nrow(X),df=df,dep_mean=mean(dd$CallsReceived),CI_low=unname(beta-qt(.975,df)*se),CI_high=unname(beta+qt(.975,df)*se),excluded_villages=paste(d$villageid[!ok],collapse=','))
 for(pair in list(c('beta','paper_beta'),c('HC2_SE','paper_SE'),c('p','paper_p'),c('R2','paper_R2'))){z[[pair[2]]]<-target[[pair[2]]][i];z[[paste0(pair[1],'_matches_3dp')]]<-sprintf('%.3f',z[[pair[1]]])==sprintf('%.3f',z[[pair[2]]])}
 z
})
out<-do.call(rbind,out);write.csv(out,'results/figure2_table_s2_comparison.csv',row.names=FALSE)
stopifnot(all(out$N==68),all(out$excluded_villages=='62'),all(out[,grepl('matches',names(out))]))
write_json(list(date='2026-10-28',status='PASS',models=nrow(out),scope='Eight independently rebuilt network layers + supplied backbone; original village outcome data; HC2 independent OLS',runtime_seconds=proc.time()[['elapsed']]-t0,R=R.version.string,packages=list(haven=as.character(packageVersion('haven')),jsonlite=as.character(packageVersion('jsonlite')))), 'results/run_summary.json',pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file='results/sessionInfo.txt')
print(out[c('term','beta','HC2_SE','p','R2','N')]);cat('All 9 coefficients, HC2 SEs, p values, R squared and sample sizes match.\n')
