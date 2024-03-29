library(readxl)
library(stringr)
library(hablar)
library(reshape)
library(Hmisc)
library(tidyverse)

# define custom color palette
myPalette <- c("#8961b3","#b55960","#999c47")

data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/Physiology_Tests',data_dir)

file_names <- list.files(path=data_dir,pattern='*2022.xlsx')

# prepare data
make_table <- 1
for(f in file_names){
  tmp <- read_excel(str_c(data_dir,'/',f),sheet='HRV Stats',n_max=25)
  tmp <- as_tibble(t(tmp),name_repair=T)
  names(tmp) <- as.character(as.vector(tmp[1,]))
  tmp <- tmp[-1,]
  tmp$Minute <- as.numeric(row.names(tmp))
  tmp <- tmp %>% retype()
  tmp$Participant <- substr(f,6,7)
  
  if(str_detect(f,'08')){
    tmp$Order <- 'Canal - Concha'
  }else if(str_detect(f,'sham')){
    tmp$Order <- 'Sham - Sham'
  }else{
    tmp$Order <- 'Concha - Canal'
  }
  if(make_table==1){
    data <- tmp
    make_table=0
  }else{
    data <- rbind(data,tmp)
  }
}
# make_table <- 1
# for(f in file_names){
#   tmp <- read_excel(str_c(data_dir,'/',f),sheet='Power Band Stats',n_max=9)
#   tmp <- as_tibble(t(tmp))
#   names(tmp) <- as.character(as.vector(tmp[1,]))
#   tmp <- tmp[-1,]
#   tmp$Minute <- as.numeric(row.names(tmp))
#   
#   tmp <- tmp %>% retype()
#   tmp$Participant <- substr(f,6,7)
#   if(str_detect(f,'08')){
#     tmp$Order <- 'Canal - Concha'
#   }else{
#     tmp$Order <- 'Concha - Canal'
#   }
#   if(make_table==1){
#     data2 <- tmp
#     make_table=0
#   }else{
#     data2 <- rbind(data2,tmp)
#   }
# }
# 
# data <- merge(data,data2)

data <- data[,c("Participant", "Order","Minute","Mean Heart Rate", "RSA","Mean IBI","SDNN","RMSSD",'AVNN','NN50','pNN50')]
data <- data[order(data$Minute),]

data %>%
  ggplot(aes(x=pNN50,fill=Order))+
  geom_histogram()+
  ggpubr::theme_pubclean()


# log transform specific variables
data$SDNN <- log(data$SDNN)
data$RMSSD <- log(data$RMSSD)

# add in info on block types
data$BlockType <- ''
data$BlockType[data$Minute<6] <- 'Baseline'
data$BlockType[data$Minute > 5 & data$Minute<11] <- 'Stim-A1'
data$BlockType[data$Minute > 10 & data$Minute<16] <- 'Washout1'
data$BlockType[data$Minute > 15 & data$Minute<21] <- 'Stim-A2'
data$BlockType[data$Minute > 20 & data$Minute<26] <- 'Washout2'
data$BlockType[data$Minute > 25 & data$Minute<31] <- 'Stim-B1'
data$BlockType[data$Minute > 30 & data$Minute<36] <- 'Washout3'
data$BlockType[data$Minute > 35 & data$Minute<=41] <- 'Stim-B2'
data$BlockType <- factor(data$BlockType, levels=c('Baseline','Stim-A1','Washout1','Stim-A2',
                                                  'Washout2','Stim-B1','Washout3','Stim-B2'))

# melt data
data <- melt(data.frame(data),id=c('BlockType','Minute','Participant','Order'))

# center to baseline
for(p in unique(data$Participant)){
  for(v in unique(data$variable)){
    base_mean = mean(data[data$Participant==p & data$variable==v & data$BlockType=='Baseline','value'])
    base_std = sd(data[data$Participant==p & data$variable==v & data$BlockType=='Baseline','value'])
    data[data$Participant==p & data$variable==v,'cValue'] <- (data[data$Participant==p & data$variable==v,'value'] - base_mean)
    data[data$Participant==p & data$variable==v,'zValue'] <- (data[data$Participant==p & data$variable==v,'value'] - base_mean)/base_std
    }
}

data %>% ggplot(aes(x=zValue))+
  geom_histogram()+
  facet_grid(Participant~variable,scales='free')+
  theme_bw()

# plot mean for each individual
data.summary <- data %>% group_by(Participant,Order,BlockType,variable) %>% summarise(value=mean(zValue,na.rm=T))
data.summary %>% 
  ggplot(aes(x=BlockType,y=value,color=Order,group=Participant))+
  #geom_boxplot()+
  geom_point()+
  geom_line()+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z)')

# calculate mean and standard deviation at group level
# data.summary <- data %>% group_by(BlockType,variable) %>% summarise(mean=mean(value,na.rm=T),std=sd(value,na.rm=T),n=n()) %>%
#   mutate(se=std/sqrt(n))

# calculate mean and 95% CI for each variable
data.summary <- data %>% 
  select(BlockType,variable,zValue) %>%
  group_by(BlockType,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=BlockType,y=Mean,group=''))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# calculate mean and 95% CI for each group and variable
data.summary <- data %>% 
  select(Order,BlockType,variable,zValue) %>% # here, change to value/cValue/zValue
  group_by(Order,BlockType,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)


data.summary %>% filter(variable %in% c('RSA','RMSSD'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)


data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','NN50','pNN50'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  scale_color_manual(values=myPalette)



p <- data.summary %>% filter(variable %in% c('RSA','RMSSD'), 
                        BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                        Order %in% c('Concha - Canal','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(2,1)],label=c('Concha','Sham'))

ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/concha_agg.png", width = 20, height = 10, units = "cm")



p <- data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','pNN50'), 
                             BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                             Order %in% c('Concha - Canal','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(2,1)],label=c('Concha','Sham'))

ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/concha_agg_altmetrics.png", width = 20, height = 15, units = "cm")


p <- data.summary %>% filter(variable %in% c('RSA','RMSSD'), 
                        BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                        Order %in% c('Canal - Concha','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(3,1)],label=c('Canal','Sham'))
ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/canal_agg.png", width = 20, height = 10, units = "cm")




p <- data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','pNN50'), 
                             BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                             Order %in% c('Canal - Concha','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(3,1)],label=c('Canal','Sham'))

ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/canal_agg_altmetrics.png", width = 20, height = 15, units = "cm")




data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','pNN50'),
                        BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2'),
                        Order %in% c('Concha - Canal','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(2,1)],label=c('Concha','Sham'))


data.summary %>% filter(variable %in% c('Mean.Heart.Rate','Mean.IBI','SDNN','pNN50'),
                        BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2'),
                        Order %in% c('Canal - Concha','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Order,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(3,1)],label=c('Concha','Sham'))



# calculate mean and 95% CI for each group and variable
data.summary <- data %>% 
  select(Order,BlockType,Participant,variable,zValue) %>% # here, change to value/cValue/zValue
  group_by(Order,BlockType,Participant,variable) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)


p <- data.summary %>% filter(variable %in% c('RSA','RMSSD'), 
                        BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                        Order %in% c('Concha - Canal','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Participant,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  #geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(2,1)],label=c('Concha','Sham'))
ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/concha_ind.png", width = 20, height = 10, units = "cm")




p <- data.summary %>% filter(variable %in% c('RSA','RMSSD'), 
                             BlockType %in% c('Baseline','Stim-A1','Washout1','Stim-A2','Washout2'),
                             Order %in% c('Canal - Concha','Sham - Sham'))%>%
  ggplot(aes(x=BlockType,y=Mean,group=Participant,color=Order))+
  geom_point()+
  geom_line()+
  geom_hline(yintercept=0)+
  #geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap('variable',scales='free_y')+
  ggpubr::theme_pubclean()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylab('Mean (z) ±95% CI')+
  theme(legend.title = element_blank(),legend.text=element_text(size=15))+
  scale_color_manual(values=myPalette[c(3,1)],label=c('Canal','Sham'))
ggsave("/Users/williamschuerman/Desktop/SRA Presentation Figures/canal_ind.png", width = 20, height = 10, units = "cm")


# 
# #### Just selecting one type of stimulation
# data$StimType <- 'Sham'
# data$StimType[data$BlockType=='Stim-A1' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Stim-A2' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Stim-B1' & data$Order=='Canal - Concha'] <- 'Concha'
# data$StimType[data$BlockType=='Stim-B2' & data$Order=='Canal - Concha'] <- 'Concha'
# data$StimType[data$BlockType=='Stim-A1' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Stim-A2' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Stim-B1' & data$Order=='Concha - Canal'] <- 'Canal'
# data$StimType[data$BlockType=='Stim-B2' & data$Order=='Concha - Canal'] <- 'Canal'
# data$StimType[data$BlockType=='Baseline' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Baseline' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Washout1' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Washout1' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Washout2' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Washout2' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Washout3' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Washout3' & data$Order=='Canal - Concha'] <- 'Canal'
# data$StimType[data$BlockType=='Washout4' & data$Order=='Concha - Canal'] <- 'Concha'
# data$StimType[data$BlockType=='Washout5' & data$Order=='Canal - Concha'] <- 'Canal'
# 
# data$StimType <- as.factor(data$StimType)
# 
# 
# ###
# 
# # calculate mean and 95% CI for each group and variable
# data.summary <- data %>% 
#   select(StimType,BlockType,variable,zValue) %>% # here, change to value/cValue/zValue
#   group_by(StimType,BlockType,variable) %>%
#   summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
#   tidyr::unnest_wider(data)
# 
# 
# data.summary %>% filter(variable %in% c('RSA','RMSSD'),StimType!='Canal') %>% 
#   ggplot(aes(x=BlockType,y=Mean,group=StimType,color=StimType))+
#   geom_point()+
#   geom_line()+
#   geom_hline(yintercept=0)+
#   geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
#   facet_wrap('variable',scales='free_y')+
#   ggpubr::theme_pubclean()+
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
#   ylab('Mean (z) ±95% CI')+
#   scale_color_manual(values=myPalette[c(2,1)])
# 
# data.summary %>% filter(variable %in% c('RSA','RMSSD'),StimType!='Concha') %>% 
#   ggplot(aes(x=BlockType,y=Mean,group=StimType,color=StimType))+
#   geom_point()+
#   geom_line()+
#   geom_hline(yintercept=0)+
#   geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
#   facet_wrap('variable',scales='free_y')+
#   ggpubr::theme_pubclean()+
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
#   ylab('Mean (z) ±95% CI')+
#   scale_color_manual(values=myPalette[c(3,1)])
# 


#### Plot difference from previous block #####
# 
# 
# # calculate difference of means and medians 
# data.summary <- data %>% group_by(Participant,variable,BlockType) %>%
#   summarize(mean = mean(value),median=median(value))
# 
# # compute effect sizes
# Concha30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Stim-A1'] - data.summary$mean[data.summary$BlockType=='Baseline']
# Concha30Hz1_median <- data.summary$median[data.summary$BlockType=='Stim-A1'] - data.summary$median[data.summary$BlockType=='Baseline']
# Concha30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Stim-A2'] - data.summary$mean[data.summary$BlockType=='Washout1']
# Concha30Hz2_median <- data.summary$median[data.summary$BlockType=='Stim-A2'] - data.summary$median[data.summary$BlockType=='Washout1']
# Canal30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Stim-B1'] - data.summary$mean[data.summary$BlockType=='Washout2']
# Canal30Hz1_median <- data.summary$median[data.summary$BlockType=='Stim-B1'] - data.summary$median[data.summary$BlockType=='Washout2']
# Canal30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Stim-B2'] - data.summary$mean[data.summary$BlockType=='Washout3']
# Canal30Hz2_median <- data.summary$median[data.summary$BlockType=='Stim-B2'] - data.summary$median[data.summary$BlockType=='Washout3']
# 
# # calculate difference of means and medians 
# data.summary <- data %>% group_by(Participant,variable) %>% summarise()
# data.summary$Concha30Hz1_mean <- Concha30Hz1_mean
# data.summary$Concha30Hz1_median <- Concha30Hz1_median
# data.summary$Concha30Hz2_mean <- Concha30Hz2_mean
# data.summary$Concha30Hz2_median <- Concha30Hz2_median
# data.summary$Canal30Hz1_mean <- Canal30Hz1_mean
# data.summary$Canal30Hz1_median <- Canal30Hz1_median
# data.summary$Canal30Hz2_mean <- Canal30Hz2_mean
# data.summary$Canal30Hz2_median <- Canal30Hz2_median
# 
# # re-melt data
# data.summary <- melt(as.data.frame(data.summary),id=c('Participant','variable'))
# names(data.summary) <- c('Participant','Variable','Effect','Value')
# 
# 
# data.summary$Effect <- factor(data.summary$Effect,levels = c("Concha30Hz1_mean", "Concha30Hz1_median", "Concha30Hz2_mean", 
#                                                              "Concha30Hz2_median", "Canal30Hz1_mean", "Canal30Hz1_median", 
#                                                              "Canal30Hz2_mean", "Canal30Hz2_median"))
# 
# # plot difference in effect sizes
# 
# data.summary %>% ggplot(aes(x=Effect,y=Value))+
#   geom_boxplot()+
#   geom_point(aes(x=Effect,y=Value,color=Participant))+
#   geom_hline(yintercept=0)+
#   facet_wrap('Variable',scales='free_y')+
#   theme_bw()+
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
# 
# # 
# ####
# 
# # calculate difference of means and medians 
# data.summary <- data %>% group_by(Participant,BlockType) %>%
#   summarize(mean = mean(value,na.rm=T),median=median(value,na.rm=T))
# 
# # compute effect sizes
# Concha30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Stim-A1'] - data.summary$mean[data.summary$BlockType=='Baseline']
# Concha30Hz1_median <- data.summary$median[data.summary$BlockType=='Stim-A1'] - data.summary$median[data.summary$BlockType=='Baseline']
# Concha30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Stim-A2'] - data.summary$mean[data.summary$BlockType=='Washout1']
# Concha30Hz2_median <- data.summary$median[data.summary$BlockType=='Stim-A2'] - data.summary$median[data.summary$BlockType=='Washout1']
# Canal30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Stim-B1'] - data.summary$mean[data.summary$BlockType=='Washout2']
# Canal30Hz1_median <- data.summary$median[data.summary$BlockType=='Stim-B1'] - data.summary$median[data.summary$BlockType=='Washout2']
# Canal30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Stim-B2'] - data.summary$mean[data.summary$BlockType=='Washout3']
# Canal30Hz2_median <- data.summary$median[data.summary$BlockType=='Stim-B2'] - data.summary$median[data.summary$BlockType=='Washout3']
# 
# # calculate difference of means and medians 
# data.summary <- data %>% group_by(Participant,variable) %>% summarise()
# data.summary$Concha30Hz1_mean <- Concha30Hz1_mean
# data.summary$Concha30Hz1_median <- Concha30Hz1_median
# data.summary$Concha30Hz2_mean <- Concha30Hz2_mean
# data.summary$Concha30Hz2_median <- Concha30Hz2_median
# data.summary$Canal30Hz1_mean <- Canal30Hz1_mean
# data.summary$Canal30Hz1_median <- Canal30Hz1_median
# data.summary$Canal30Hz2_mean <- Canal30Hz2_mean
# data.summary$Canal30Hz2_median <- Canal30Hz2_median
# 
# # re-melt data
# data.summary[data.summary$variable=='',] <- NULL
# data.summary <- melt(as.data.frame(data.summary),id=c('Participant'))
# names(data.summary) <- c('Participant','Effect','Value')
# 
# data.summary$Effect <- factor(data.summary$Effect,levels = c("Concha30Hz1_mean", "Concha30Hz1_median", "Concha30Hz2_mean", 
#                                                              "Concha30Hz2_median", "Canal30Hz1_mean", "Canal30Hz1_median", 
#                                                              "Canal30Hz2_mean", "Canal30Hz2_median"))
# 
# data.summary %>% ggplot(aes(x=Effect,y=Value,color=Participant))+
#   geom_point()+
#   geom_hline(yintercept=0)+
#   theme_bw()+
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
# 
# 
# data.summary %>% ggplot(aes(x=Effect,y=Value))+
#   geom_boxplot()+
#   geom_point(aes(x=Effect,y=Value,color=Participant))+
#   geom_hline(yintercept=0)+
#   theme_bw()+
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
# 
