library(readxl)
library(stringr)
library(hablar)
library(reshape)
library(Hmisc)
library(tidyverse)

# define custom color palette
myPalette <- c("#8961b3","#b55960","#999c47")

data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/SART_Microstudy/Physiology/',data_dir)

file_names <- list.files(path=data_dir,pattern='*.xlsx')

# prepare data
make_table <- 1
for(f in file_names){
  tmp <- read_excel(str_c(data_dir,'/',f),sheet='HRV Stats',n_max=25)
  tmp <- as_tibble(t(tmp),name_repair=T)
  names(tmp) <- as.character(as.vector(tmp[1,]))
  tmp <- tmp[-1,]
  tmp$Minute <- as.numeric(row.names(tmp))
  tmp <- tmp %>% retype()
  tmp$Participant <- substr(f,5,7)

  if(make_table==1){
    data <- tmp
    make_table=0
  }else{
    data <- rbind(data,tmp)
  }
}

# Add blocks labels
data$Block <- 'Baseline'
data$Block[data$Minute > 5 & data$Minute<=10] <- 'SART 1'
data$Block[data$Minute > 10 & data$Minute<=15] <- 'SART 2'
data$Block[data$Minute > 15 & data$Minute<=20] <- 'Recovery 1'
data$Block[data$Minute > 20 & data$Minute<=25] <- 'SART 3'
data$Block[data$Minute > 25 & data$Minute<=30] <- 'SART 4'
data$Block[data$Minute > 30 & data$Minute<=35] <- 'Recovery 2'

data$Block <- factor(data$Block,levels = c('Baseline','SART 1','SART 2',
                                           'Recovery 1','SART 3','SART 4',
                                           'Recovery 2'))


data$Stim <- FALSE
data$Stim[as.numeric(data$Participant) %% 2 ==0 & 
       data$Block %in% c('SART 1','SART 2')] <- TRUE
data$Stim[as.numeric(data$Participant) %% 2 ==1 & 
            data$Block %in% c('SART 3','SART 4')] <- TRUE


data <- data[,c("Participant","Block","Stim","Minute","Mean Heart Rate", 
                "RSA","Mean IBI","SDNN","RMSSD",'AVNN','NN50','pNN50')]
data <- data[order(data$Minute),]

# log transform specific variables
data$SDNN <- log(data$SDNN)
data$RMSSD <- log(data$RMSSD)

# melt data
data <- melt(data.frame(data),id=c('Participant','Block','Stim','Minute'))

# center to baseline
for(p in unique(data$Participant)){
  for(v in unique(data$variable)){
    base_mean = mean(data[data$Participant==p & data$variable==v & data$Block=='Baseline','value'],na.rm=T)
    base_std = sd(data[data$Participant==p & data$variable==v & data$Block=='Baseline','value'],na.rm=T)
    data[data$Participant==p & data$variable==v,'cValue'] <- (data[data$Participant==p & data$variable==v,'value'] - base_mean)
    data[data$Participant==p & data$variable==v,'zValue'] <- (data[data$Participant==p & data$variable==v,'value'] - base_mean)/base_std
  }
}

data %>% ggplot(aes(x=zValue))+
  geom_histogram()+
  facet_grid(Participant~variable,scales='free')+
  theme_bw()

# plot mean for each individual
data.summary <- data %>% group_by(Participant,Block,Stim,variable) %>% summarise(value=mean(zValue,na.rm=T))
data.summary %>% 
  ggplot(aes(x=Block,y=value,color=Stim,group=Participant))+
  geom_point()+
  geom_line()+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z)')+
  scale_color_manual(values=myPalette)

# calculate mean and standard deviation at group level
# data.summary <- data %>% group_by(Block,variable) %>% summarise(mean=mean(value,na.rm=T),std=sd(value,na.rm=T),n=n()) %>%
#   mutate(se=std/sqrt(n))

# calculate mean and 95% CI for each variable
data.summary <- data %>% 
  select(Block,variable,zValue) %>%
  group_by(Block,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=Block,y=Mean,group=''))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# calculate mean and 95% CI for each group and variable
data.summary <- data %>% 
  select(Stim,Participant,Block,variable,value) %>% # here, change to value/cValue/zValue
  group_by(Stim,Participant,Block,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=Block,y=Mean,group=Participant,color=Stim))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)


data.summary %>% filter(variable %in% c('RSA','RMSSD','SDNN'))%>%
  ggplot(aes(x=Block,y=Mean,shape=Participant,color=Stim))+
  #geom_hline(yintercept=0)+
  geom_point(position=position_dodge(0.5),size=3)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1,
                position=position_dodge(0.5),linetype=1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)

data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','NN50','pNN50'))%>%
  ggplot(aes(x=Block,y=Mean,shape=Participant,color=Stim))+
  geom_point(position=position_dodge(0.5),size=3)+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1,
                position=position_dodge(0.5))+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)



# calculate mean and 95% CI for each group and variable
data.summary <- data %>% 
  select(Stim,Block,Participant,variable,zValue) %>% # here, change to value/cValue/zValue
  group_by(Stim,Block,Participant,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)


data.summary %>% filter(variable %in% c('RSA','RMSSD'))%>%
  ggplot(aes(x=Block,y=Mean,color=Participant,group=Participant,shape=Participant))+
  geom_hline(yintercept=0)+
  geom_line(position=position_dodge(0.5))+
  geom_point(position=position_dodge(0.5),size=3)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1,
                position=position_dodge(0.5),linetype=1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')

p <- data.summary %>% filter(variable %in% c('RSA','RMSSD'))%>% 
  ggplot(aes(x=Block,y=Mean,color=Participant,shape=Participant,group=Participant))+
  geom_line(position=position_dodge(0.5))+
  geom_point(position=position_dodge(0.5),size=3)+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1,position=position_dodge(0.5))+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')
  #scale_color_manual(values=myPalette,name='tVNS')

p
#ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/concha_ind.png", width = 20, height = 10, units = "cm")

