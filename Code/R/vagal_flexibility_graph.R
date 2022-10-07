library(tidyverse)

password_mean <- -0.49
password_sd <- 1.2

improv_mean <- -0.49
improv_sd <- 1.13

wordcontext_mean <- -0.24
wordcontext_sd <- 1.02

questions_mean <- -0.56
questions_sd <- 0.98

category_mean <- -0.22
category_sd <- 0.95


n = 198

means <- c(password_mean,improv_mean,wordcontext_mean,questions_mean,
           category_mean)
sds <- c(password_sd,improv_sd,wordcontext_sd,questions_sd,
  category_sd)

variable <- c('Password', 'Improvisation', 'Word Context', '20 Questions','Category Switch')

d <- data.frame(variable,means,sds,n)
d$upper <- d$means + 1.96*d$sds/sqrt(d$n)
d$lower <- d$means - 1.96*d$sds/sqrt(d$n)

d %>% ggplot(aes(x=variable,y=means))+
  geom_hline(yintercept=0)+
  geom_point()+
  geom_errorbar(aes(ymin=lower,ymax=upper),width=0.2)+
  ggpubr::theme_pubr()+
  ylab('Average Decrease in RSA')


##### Shame graph ####

x <- c(-1,  0, 1)
y <- c(1.58, 1.38,1.19)
d <- data.frame(x,y)
ggplot(d,aes(x=x,y=y))+
  geom_point()+
  geom_line()+
  ggpubr::theme_pubr()+
  xlab('Vagal Flexibility')+
  ylab('Self-reported Shame')
  
  