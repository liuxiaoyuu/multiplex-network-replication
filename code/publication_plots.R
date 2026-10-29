library(ggplot2)
z<-read.csv('results/measurement_sensitivity.csv')
z$label<-c('Original sample (68)','Recorded seed count added (68)','Equal seed counts only (39)')
p<-ggplot(z,aes(C_minus_B_RMSE,factor(label,levels=rev(z$label))))+
 geom_vline(xintercept=0,linetype='dashed',color='grey50')+geom_point(size=3,color='#245b82')+
 geom_text(aes(label=sprintf('%+.3f',C_minus_B_RMSE)),nudge_y=.22,size=3.6)+
 labs(title='Measurement and sample choices matter',subtitle='Refitted leave-one-village-out comparisons',x='RMSE: five-layer OLS minus advice OLS',y=NULL,
 caption='Negative values favor five layers. The subset changes the target population; it is not a missingness correction.')+
 theme_minimal(base_size=11)+theme(panel.grid.major.y=element_blank(),panel.grid.minor=element_blank(),plot.title=element_text(face='bold'),plot.caption=element_text(hjust=0))
ggsave('results/measurement_sensitivity.png',p,width=8.8,height=3.7,dpi=200)
z<-read.csv('results/deletion_sensitivity.csv')
p<-ggplot(z,aes(C_minus_B_RMSE))+geom_histogram(binwidth=.05,boundary=0,fill='#245b82',color='white')+
 geom_vline(xintercept=0,linetype='dashed')+
 labs(title='Full refitting after each village deletion',subtitle='68 leave-one-village-deleted datasets, each evaluated with 67-fold LOO',x='RMSE: five-layer OLS minus advice OLS',y='Number of deletions',caption='The contrast is positive in 66 of 68 deletions. This range is a sensitivity summary, not a confidence interval.')+
 theme_minimal(base_size=11)+theme(panel.grid.minor=element_blank(),plot.title=element_text(face='bold'),plot.caption=element_text(hjust=0))
ggsave('results/deletion_sensitivity.png',p,width=8.8,height=4.2,dpi=200)
