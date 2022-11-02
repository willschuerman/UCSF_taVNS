library(hablar)
library(stringr)
library(Rmisc)
library(tidyverse)

# define custom color palette
myPalette <- c("#8961b3","#b55960","#999c47")

data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/SART_Tests',data_dir)

file_names <- list.files(path=data_dir,pattern='*GDryRunLi')

#### prepare data ####
make_table=1
for(f in file_names){
  tmp <- read_csv(str_c(data_dir,'/',f))
  tmp <- tmp %>% retype()
  tmp$stimblock = 0
  if(any(tmp$blocknum>0)){
    if(all(tmp$subject %% 2 == 0)){
      tmp[tmp$blocknum<3,]$stimblock =1
    }else{
      tmp[tmp$blocknum>2,]$stimblock =1
    }
  }

  if(make_table==1){
    data <- tmp
    make_table=0
  }else{
    data <- rbind(data,tmp)
  }
}

#### visualize RT ####

d <- summarySE(data,measurevar='values.RT',groupvars=c('blocknum','stimblock'))
d$stimblock <- as.factor(d$stimblock)
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=values.RT,color=stimblock))+
  geom_point()+
  geom_errorbar(aes(ymin=values.RT-ci,ymax=values.RT+ci),width=0.1)+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)


d <- summarySE(data[data$blocknum>0,],measurevar='values.RT',groupvars=c('blocknum','stimblock','trialcode'))
d$stimblock <- as.factor(d$stimblock)
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=values.RT,color=stimblock))+
  geom_point()+
  geom_errorbar(aes(ymin=values.RT-ci,ymax=values.RT+ci),width=0.1)+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)+
  facet_wrap('trialcode')

d <- summarySE(data,measurevar='correct',groupvars=c('blocknum','stimblock'))
d$stimblock <- as.factor(d$stimblock)
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=correct,color=stimblock))+
  geom_point()+
  geom_errorbar(aes(ymin=correct-ci,ymax=correct+ci),width=0.1)+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)


d <- summarySE(data[data$blocknum>0,],measurevar='correct',groupvars=c('blocknum','stimblock','trialcode'))
d$stimblock <- as.factor(d$stimblock)
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=correct,color=stimblock))+
  geom_point()+
  geom_errorbar(aes(ymin=correct-ci,ymax=correct+ci),width=0.1)+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)+
  facet_wrap('trialcode')

