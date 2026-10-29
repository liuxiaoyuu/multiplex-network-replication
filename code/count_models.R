# Penalized Poisson mean models: independent implementation, base R only.
count_grid <- 10^seq(-4, 2, length.out=25)
count_design <- function(train, test, vars) {
  des <- make_design(train, test, c('dummy_3_seeds', vars))
  list(X=des$X, Xt=des$Xt, offset=log(train$num_hh_random),
       offset_test=log(test$num_hh_random), penalty=c(0, 0, rep(1, length(vars))))
}
poisson_deviance <- function(y, mu) {
  stopifnot(all(is.finite(mu)), all(mu>0), all(y>=0))
  z <- mu-y; keep <- y>0
  z[keep] <- z[keep]+y[keep]*log(y[keep]/mu[keep])
  2*z
}
poisson_fit <- function(des, y, lambda, bfgs=FALSE) {
  X <- des$X; off <- des$offset; pen <- des$penalty; n <- length(y)
  objective <- function(b) {
    eta <- drop(off+X%*%b)
    if(any(!is.finite(eta)) || max(eta)>700) return(Inf)
    mean(exp(eta)-y*eta)+lambda/2*sum(pen*b*b)
  }
  gradient <- function(b) drop(crossprod(X, exp(off+X%*%b)-y))/n+lambda*pen*b
  b <- c(log(sum(y)/sum(exp(off))), rep(0, ncol(X)-1))
  if(bfgs) {
    fit <- optim(b, objective, gradient, method='BFGS', control=list(reltol=1e-13,maxit=2000))
    b <- fit$par; it <- fit$counts[['gradient']]
  } else {
    for(it in 1:100) {
      g <- gradient(b)
      if(max(abs(g))<1e-8) break
      mu <- drop(exp(off+X%*%b))
      H <- crossprod(X, X*mu)/n+diag(lambda*pen)
      step <- solve(H,g); old <- objective(b); alpha <- 1
      while(objective(b-alpha*step)>old-1e-4*alpha*sum(g*step) && alpha>2^-35) alpha <- alpha/2
      b <- b-alpha*step
    }
  }
  gap <- max(abs(gradient(b))); pred <- drop(exp(des$offset_test+des$Xt%*%b))
  list(beta=b, predicted=pred, gradient=gap, iterations=it,
       objective=objective(b), converged=is.finite(gap)&&gap<1e-6&&all(is.finite(pred))&&all(pred>0))
}
count_predict <- function(train,test,vars,lambda,bfgs=FALSE) {
  poisson_fit(count_design(train,test,vars),train$CallsReceived,lambda,bfgs)
}
tune_count <- function(train,seed,vars) {
  fold <- fold_labels(nrow(train),seed); losses <- numeric(length(count_grid)); gaps <- numeric()
  for(j in seq_along(count_grid)) {
    pred <- numeric(nrow(train))
    for(k in 1:5) {
      fit <- count_predict(train[fold!=k,],train[fold==k,],vars,count_grid[j])
      if(!fit$converged) stop('Poisson inner fit failed: seed=',seed,', lambda=',count_grid[j],', fold=',k,', gradient=',fit$gradient)
      pred[fold==k] <- fit$predicted; gaps <- c(gaps,fit$gradient)
    }
    losses[j] <- mean(poisson_deviance(train$CallsReceived,pred))
  }
  eligible <- which(losses<=min(losses)+1e-12*max(1,abs(min(losses))))
  list(lambda=count_grid[max(eligible)],losses=losses,max_gradient=max(gaps))
}
