library(haven);library(jsonlite)
source('code/predictive_models.R');source('code/count_models.R')
t0 <- proc.time()[['elapsed']]
d <- as.data.frame(read_dta('private_inputs/rct_village_diffusion_outcomes.dta'))
cens <- read.csv('results/rebuilt_seed_centrality.csv')
d <- d[!is.na(d$villageid)&d$villageid %in% c(1:26,28:39,41:71),]
d <- d[order(d$villageid),];cens <- cens[match(d$villageid,cens$village),]
d <- cbind(d,cens[setdiff(names(cens),'village')])
d$dummy_3_seeds <- as.numeric(d$num_seeds==3)
d$num_hh_random_sq <- d$num_hh_random^2;d$num_hh_random_cb <- d$num_hh_random^3
d <- d[complete.cases(d[c('CallsReceived',controls,netvars)]),]
stopifnot(nrow(d)==68)
audit <- read.csv('results/node_seed_audit.csv')
print(names(audit))
# Names fixed to the independently generated seed audit, not inferred from outcomes.
seed_col <- 'seed_count'
stopifnot(seed_col %in% names(audit))
d$recorded_seeds <- audit[[seed_col]][match(d$villageid,audit$village)]
count_rows <- list();tuning <- list();gradients <- numeric();optimizer_gaps <- numeric();leakage_gaps <- numeric()
run_count_outer <- function(train,test,seed,scheme,r,k) {
  for(model in c('Rate','P_advice','P_five')) {
    if(model=='Rate') {pred <- test$num_hh_random*sum(train$CallsReceived)/sum(train$num_hh_random);lambda <- NA_real_
    } else {
      vars <- if(model=='P_advice')'sum_advice' else netvars
      tune <- tune_count(train,seed,vars);lambda <- tune$lambda
      tuning[[length(tuning)+1L]] <<- data.frame(scheme=scheme,repeat_id=r,fold_id=k,model=model,lambda=count_grid,deviance=tune$losses,selected=count_grid==lambda)
      fit <- count_predict(train,test,vars,lambda);stopifnot(fit$converged)
      pred <- fit$predicted;gradients <<- c(gradients,tune$max_gradient,fit$gradient)
      if(scheme=='LOO' && k %in% c(1,17,34,51,68)) {
        alt <- count_predict(train,test,vars,lambda,TRUE)
        optimizer_gaps <<- c(optimizer_gaps,max(abs(alt$predicted-pred)))
        test2 <- test;test2$CallsReceived <- test2$CallsReceived+100000
        leakage_gaps <<- c(leakage_gaps,max(abs(count_predict(train,test2,vars,lambda)$predicted-pred)))
      }
    }
    count_rows[[length(count_rows)+1L]] <<- data.frame(scheme=scheme,repeat_id=r,fold_id=k,village=test$villageid,model=model,observed=test$CallsReceived,predicted=pred,lambda=lambda,train_n=nrow(train))
  }
}
for(i in seq_len(nrow(d))) {
  run_count_outer(d[-i,],d[i,,drop=FALSE],20261028+d$villageid[i],'LOO',0,i)
  if(i%%10==0)cat('Poisson LOO',i,'/68\n')
}
for(r in 1:10) {
  folds <- fold_labels(nrow(d),20261028+r)
  for(k in 1:5)run_count_outer(d[folds!=k,],d[folds==k,],20261028+1000*r+k,'5fold',r,k)
  cat('Poisson five-fold repetition',r,'/10\n')
}
a <- do.call(rbind,count_rows);a$squared_error <- (a$observed-a$predicted)^2
a$absolute_error <- abs(a$observed-a$predicted);a$deviance <- poisson_deviance(a$observed,a$predicted)
write.csv(a,'results/count_predictions.csv',row.names=FALSE)
write.csv(do.call(rbind,tuning),'results/count_tuning.csv',row.names=FALSE)
metrics <- do.call(rbind,lapply(split(a,interaction(a$scheme,a$repeat_id,a$model,drop=TRUE)),function(z)
  data.frame(scheme=z$scheme[1],repeat_id=z$repeat_id[1],model=z$model[1],N=nrow(z),RMSE=sqrt(mean(z$squared_error)),MAE=mean(z$absolute_error),deviance=mean(z$deviance))))
write.csv(metrics,'results/count_metrics.csv',row.names=FALSE)
press_pred <- function(z,vars) {
  des <- make_design(z,z,vars);fit <- lm.fit(des$X,z$CallsReceived)
  stopifnot(fit$rank==ncol(des$X))
  h <- rowSums(qr.Q(fit$qr)^2);stopifnot(all(h<1))
  z$CallsReceived-fit$residuals/(1-h)
}
contrast <- function(z,extra=character()) {
  b <- press_pred(z,c(variables('B_advice'),extra));cc <- press_pred(z,c(variables('C_five_OLS'),extra))
  data.frame(N=nrow(z),B_RMSE=sqrt(mean((z$CallsReceived-b)^2)),C_RMSE=sqrt(mean((z$CallsReceived-cc)^2)),B_MAE=mean(abs(z$CallsReceived-b)),C_MAE=mean(abs(z$CallsReceived-cc)))
}
sens <- rbind(cbind(specification='Original',contrast(d)),
              cbind(specification='Add_recorded_seeds',contrast(d,'recorded_seeds')),
              cbind(specification='Equal_seed_counts_subset',contrast(d[d$recorded_seeds==d$num_seeds,])))
sens$C_minus_B_RMSE <- sens$C_RMSE-sens$B_RMSE
write.csv(sens,'results/measurement_sensitivity.csv',row.names=FALSE)
deletion <- do.call(rbind,lapply(seq_len(nrow(d)),function(i)cbind(deleted_village=d$villageid[i],contrast(d[-i,]))))
deletion$C_minus_B_RMSE <- deletion$C_RMSE-deletion$B_RMSE
write.csv(deletion,'results/deletion_sensitivity.csv',row.names=FALSE)
old <- read.csv('results/heldout_predictions.csv');fold <- old[old$scheme=='5fold',]
fs <- aggregate(squared_error~repeat_id+fold_id+model+train_n,fold,mean)
uncertainty <- do.call(rbind,lapply(c('C_five_OLS','D_five_ridge'),function(m) {
  bb <- fs[fs$model=='B_advice',];cc <- fs[fs$model==m,]
  pair <- merge(bb,cc,by=c('repeat_id','fold_id','train_n'),suffixes=c('_B','_C'))
  delta <- pair$squared_error_C-pair$squared_error_B;ratio <- mean((68-pair$train_n)/pair$train_n)
  se <- sqrt((1/length(delta)+ratio)*var(delta));margin <- qt(.975,length(delta)-1)*se
  data.frame(contrast=paste(m,'minus B_advice'),folds=length(delta),mean_MSE_difference=mean(delta),test_train_ratio=ratio,corrected_SE=se,lower=mean(delta)-margin,upper=mean(delta)+margin)
}))
write.csv(uncertainty,'results/corrected_resampling_intervals.csv',row.names=FALSE)
# Independent explicit refits validate PRESS after subset / control changes.
press_gaps <- numeric()
for(spec in c('add','subset')) {
  z <- if(spec=='subset')d[d$recorded_seeds==d$num_seeds,] else d
  for(m in c('B_advice','C_five_OLS')) {
    vars <- c(variables(m),if(spec=='add')'recorded_seeds')
    explicit <- vapply(seq_len(nrow(z)),function(i) {
      des <- make_design(z[-i,],z[i,,drop=FALSE],vars)
      drop(des$Xt%*%qr.coef(qr(des$X),z$CallsReceived[-i]))
    },numeric(1))
    press_gaps <- c(press_gaps,max(abs(explicit-press_pred(z,vars))))
  }
}
stopifnot(max(gradients)<1e-6,max(optimizer_gaps)<1e-3,max(leakage_gaps)==0,max(press_gaps)<1e-7)
write_json(list(status='PASS',date='2026-10-29',count_max_gradient=max(gradients),BFGS_max_prediction_gap=max(optimizer_gaps),heldout_outcome_perturbation_gap=max(leakage_gaps),sensitivity_PRESS_gap=max(press_gaps),count_inner_fits=118*2*25*5,count_outer_fits=118*2,all_fits_converged=TRUE,runtime_seconds=proc.time()[['elapsed']]-t0,plan=read_json('docs/publication_plan_lock.json')),'results/publication_validation.json',pretty=TRUE,auto_unbox=TRUE,digits=12)
print(metrics[metrics$scheme=='LOO',]);print(sens);print(uncertainty)
cat('Deletion contrast range:',range(deletion$C_minus_B_RMSE),'positive:',sum(deletion$C_minus_B_RMSE>0),'\n')
