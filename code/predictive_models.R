# Model functions take training outcomes only; preprocessing is fitted per training set.
controls<-c('dummy_3_seeds','num_hh_random','num_hh_random_sq','num_hh_random_cb')
netvars<-paste0('sum_',c('social','kerorice','advice','decision','jati'))
model_names<-c('Mean','A_controls','B_advice','C_five_OLS','D_five_ridge')
variables<-function(model)switch(model,Mean=character(),A_controls=controls,B_advice=c(controls,'sum_advice'),C_five_OLS=c(controls,netvars),D_five_ridge=c(controls,netvars))
make_design<-function(train,test,vars){
 if(!length(vars))return(list(X=matrix(1,nrow(train),1),Xt=matrix(1,nrow(test),1)))
 X<-as.matrix(train[vars]);Xt<-as.matrix(test[vars]);continuous<-setdiff(vars,'dummy_3_seeds')
 mu<-colMeans(X[,continuous,drop=FALSE]);ss<-apply(X[,continuous,drop=FALSE],2,sd)
 stopifnot(all(is.finite(ss)),all(ss>0))
 X[,continuous]<-sweep(sweep(X[,continuous,drop=FALSE],2,mu,'-'),2,ss,'/')
 Xt[,continuous]<-sweep(sweep(Xt[,continuous,drop=FALSE],2,mu,'-'),2,ss,'/')
 list(X=cbind('(Intercept)'=1,X),Xt=cbind('(Intercept)'=1,Xt))
}
fit_predict<-function(train,test,model,lambda=0){
 des<-make_design(train,test,variables(model));X<-des$X;y<-train$CallsReceived
 stopifnot(qr(X)$rank==ncol(X),all(is.finite(X)),all(is.finite(des$Xt)))
 if(model=='D_five_ridge'){
  penalty<-diag(c(rep(0,1+length(controls)),rep(1,length(netvars))))
  b<-solve(crossprod(X)/nrow(X)+lambda*penalty,crossprod(X,y)/nrow(X))
 }else b<-qr.coef(qr(X),y)
 as.numeric(des$Xt%*%b)
}
fold_labels<-function(n,seed){set.seed(seed);sample(rep(1:5,length.out=n))}
lambda_grid<-10^seq(-4,4,length.out=41)
tune_ridge<-function(train,seed){
 fold<-fold_labels(nrow(train),seed)
 losses<-vapply(lambda_grid,function(lam){
  pred<-numeric(nrow(train))
  for(k in 1:5)pred[fold==k]<-fit_predict(train[fold!=k,],train[fold==k,],'D_five_ridge',lam)
  mean((train$CallsReceived-pred)^2)
 },numeric(1))
 best<-min(losses);eligible<-which(losses<=best+1e-12*max(1,abs(best)));pick<-max(eligible)
 list(lambda=lambda_grid[pick],losses=losses,fold=fold)
}
