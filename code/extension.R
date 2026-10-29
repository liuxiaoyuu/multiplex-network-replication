# Execute only after plan hash and network reconstruction checks.
library(haven);library(jsonlite);source('code/predictive_models.R')
t0<-proc.time()[['elapsed']]
stopifnot(read_json('results/network_summary.json')$status=='PASS')
d<-as.data.frame(read_dta('private_inputs/rct_village_diffusion_outcomes.dta'))
c<-read.csv('results/rebuilt_seed_centrality.csv')
d<-d[d$villageid %in% c(1:26,28:39,41:71) & !is.na(d$villageid),]
d<-d[order(d$villageid),];c<-c[match(d$villageid,c$village),]
d<-cbind(d,c[setdiff(names(c),'village')]);d$dummy_3_seeds<-as.numeric(d$num_seeds==3)
d$num_hh_random_sq<-d$num_hh_random^2;d$num_hh_random_cb<-d$num_hh_random^3
d<-d[complete.cases(d[c('CallsReceived',controls,netvars)]),]
stopifnot(nrow(d)==68,!anyDuplicated(d$villageid),!62 %in% d$villageid)
rows<-list();tuning<-list();foldlog<-list();ridge_gaps<-numeric();leakage_gaps<-numeric()
run_outer<-function(train,test,seed,scheme,repeat_id,fold_id){
 tune<-tune_ridge(train,seed)
 tuning[[length(tuning)+1L]]<<-data.frame(scheme=scheme,repeat_id=repeat_id,fold_id=fold_id,lambda=lambda_grid,MSE=tune$losses,selected=lambda_grid==tune$lambda)
 foldlog[[length(foldlog)+1L]]<<-data.frame(scheme=scheme,repeat_id=repeat_id,outer_fold=fold_id,training_village=train$villageid,inner_fold=tune$fold)
 for(model in model_names){
  lam<-if(model=='D_five_ridge')tune$lambda else 0
  pred<-fit_predict(train,test,model,lam)
  rows[[length(rows)+1L]]<<-data.frame(scheme=scheme,repeat_id=repeat_id,fold_id=fold_id,village=test$villageid,model=model,observed=test$CallsReceived,predicted=pred,lambda=lam,train_n=nrow(train))
 }
 # Independent Frisch-Waugh + SVD ridge calculation for every LOO fit.
 if(scheme=='LOO'){
  des<-make_design(train,test,variables('D_five_ridge'));X<-des$X
  C<-X[,seq_len(5)];Z<-X[,6:10];cy<-qr(C);yr<-qr.resid(cy,train$CallsReceived);Zr<-qr.resid(cy,Z)
  s<-svd(Zr);bz<-s$v%*%((s$d/(s$d^2+nrow(train)*tune$lambda))*drop(t(s$u)%*%yr))
  bc<-qr.coef(cy,train$CallsReceived-Z%*%bz);alt<-drop(des$Xt%*%rbind(bc,bz))
  ridge_gaps<<-c(ridge_gaps,abs(alt-fit_predict(train,test,'D_five_ridge',tune$lambda)))
  if(fold_id<=2){test2<-test;test2$CallsReceived<-test2$CallsReceived+100000
   for(model in model_names)leakage_gaps<<-c(leakage_gaps,max(abs(fit_predict(train,test2,model,tune$lambda)-fit_predict(train,test,model,tune$lambda))))
  }
 }
}
for(i in seq_len(nrow(d)))run_outer(d[-i,],d[i,,drop=FALSE],20261028+d$villageid[i],'LOO',0,i)
for(r in 1:10){
 folds<-fold_labels(nrow(d),20261028+r)
 for(k in 1:5)run_outer(d[folds!=k,],d[folds==k,],20261028+1000*r+k,'5fold',r,k)
}
a<-do.call(rbind,rows);a$residual<-a$observed-a$predicted;a$squared_error<-a$residual^2;a$absolute_error<-abs(a$residual)
write.csv(a,'results/heldout_predictions.csv',row.names=FALSE)
write.csv(do.call(rbind,tuning),'results/ridge_tuning.csv',row.names=FALSE)
write.csv(do.call(rbind,foldlog),'results/inner_fold_membership.csv',row.names=FALSE)
metrics<-lapply(split(a,interaction(a$scheme,a$repeat_id,a$model,drop=TRUE)),function(z)data.frame(scheme=z$scheme[1],repeat_id=z$repeat_id[1],model=z$model[1],n=nrow(z),RMSE=sqrt(mean(z$squared_error)),MAE=mean(z$absolute_error),negative_predictions=sum(z$predicted<0),max_absolute_error=max(z$absolute_error)))
m<-do.call(rbind,metrics);rownames(m)<-NULL
m$relative_MSE_improvement<-vapply(seq_len(nrow(m)),function(i){ref<-m$RMSE[m$scheme==m$scheme[i]&m$repeat_id==m$repeat_id[i]&m$model=='Mean'];1-m$RMSE[i]^2/ref^2},numeric(1))
write.csv(m,'results/prediction_metrics.csv',row.names=FALSE)
contrasts<-lapply(split(m,interaction(m$scheme,m$repeat_id,drop=TRUE)),function(z){b<-z[z$model=='B_advice',];data.frame(scheme=z$scheme[1],repeat_id=z$repeat_id[1],C_minus_B_RMSE=z$RMSE[z$model=='C_five_OLS']-b$RMSE,D_minus_B_RMSE=z$RMSE[z$model=='D_five_ridge']-b$RMSE,C_minus_B_MAE=z$MAE[z$model=='C_five_OLS']-b$MAE,D_minus_B_MAE=z$MAE[z$model=='D_five_ridge']-b$MAE)})
write.csv(do.call(rbind,contrasts),'results/model_contrasts.csv',row.names=FALSE)
lo<-a[a$scheme=='LOO',];press<-numeric()
for(model in setdiff(model_names,'D_five_ridge')){
 des<-make_design(d,d,variables(model));f<-lm.fit(des$X,d$CallsReceived);q<-qr.Q(f$qr);h<-rowSums(q^2)
 analytical<-d$CallsReceived-f$residuals/(1-h)
 pred<-lo$predicted[lo$model==model];press[model]<-max(abs(analytical-pred))
}
B<-lo[lo$model=='B_advice',];C<-lo[lo$model=='C_five_OLS',];D<-lo[lo$model=='D_five_ridge',]
contrib<-data.frame(village=B$village,observed=B$observed,B_error=B$squared_error,C_error=C$squared_error,D_error=D$squared_error,C_minus_B=C$squared_error-B$squared_error,D_minus_B=D$squared_error-B$squared_error)
write.csv(contrib[order(-abs(contrib$C_minus_B)),],'results/village_loss_contributions.csv',row.names=FALSE)
stopifnot(all(m$n==68),all(table(a$scheme,a$model)[1,]==680),max(press)<1e-7,max(ridge_gaps)<1e-7,max(leakage_gaps)==0,all(is.finite(a$predicted)))
write_json(list(date='2026-10-28',status='PASS',N=68,models=5,outer_fits=118*5,predictions=nrow(a),runtime_seconds=proc.time()[['elapsed']]-t0,OLS_PRESS_max_gap=max(press),ridge_SVD_max_gap=max(ridge_gaps),heldout_outcome_perturbation_gap=max(leakage_gaps),primary_contrast='RMSE(C_five_OLS) minus RMSE(B_advice)',inferential_pvalues_computed=FALSE,plan=read_json('docs/plan_lock.json')),'results/extension_validation.json',pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file='results/sessionInfo_extension.txt')
print(m[m$scheme=='LOO',]);cat('Primary LOO and all ten repeated five-fold comparisons saved.\n')
