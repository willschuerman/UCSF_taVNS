library(tidyverse)
library(readxl)
library(stringr)
library(hablar)
library(reshape)

data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/Physiology_Tests',data_dir)

file_names <- list.files(path=data_dir,pattern='*2022.xlsx')

# prepare data
make_table <- 1
for(f in file_names){
  tmp <- read_excel(str_c(data_dir,'/',f),sheet='HRV Stats',n_max=25)
  tmp <- as_tibble(t(tmp))
  names(tmp) <- as.character(as.vector(tmp[1,]))
  tmp <- tmp[-1,]
  tmp$Minute <- as.numeric(row.names(tmp))
  tmp <- tmp %>% retype()
  tmp$Participant <- substr(f,6,7)
  if(make_table==1){
    data1 <- tmp
    make_table=0
  }else{
    data1 <- rbind(data1,tmp)
  }
}
make_table <- 1
for(f in file_names){
  tmp <- read_excel(str_c(data_dir,'/',f),sheet='Power Band Stats',n_max=9)
  tmp <- as_tibble(t(tmp))
  names(tmp) <- as.character(as.vector(tmp[1,]))
  tmp <- tmp[-1,]
  tmp$Minute <- as.numeric(row.names(tmp))
  
  tmp <- tmp %>% retype()
  tmp$Participant <- substr(f,6,7)
  if(make_table==1){
    data2 <- tmp
    make_table=0
  }else{
    data2 <- rbind(data2,tmp)
  }
}

data <- merge(data1,data2)

data <- data[,c("Participant", "Minute","Mean Heart Rate", "RSA", "Mean IBI", "# of R's Found", 
                "SDNN", "AVNN", "RMSSD", "NN50", "pNN50", "VLF Power", "VLF Peak Power Frequency", 
                "LF Power", "LF Peak Power Frequency", "HF/RSA Power", "HF/RSA Peak Power Frequency", 
                "LF/HF Ratio")]
data <- data[order(data$Minute),]

# add in info on block types
data$BlockType <- ''
data$BlockType[data$Minute<6] <- 'Baseline'
data$BlockType[data$Minute > 5 & data$Minute<11] <- 'Concha30Hz-1'
data$BlockType[data$Minute > 10 & data$Minute<16] <- 'Washout1'
data$BlockType[data$Minute > 15 & data$Minute<21] <- 'Concha30Hz-2'
data$BlockType[data$Minute > 20 & data$Minute<26] <- 'Washout2'
data$BlockType[data$Minute > 25 & data$Minute<31] <- 'Canal30Hz-1'
data$BlockType[data$Minute > 30 & data$Minute<36] <- 'Washout3'
data$BlockType[data$Minute > 36 & data$Minute<41] <- 'Canal30Hz-2'


# melt data
data <- melt(data,id=c('BlockType','Minute','Participant'))

# normalize within participant and variable
data <- data %>%
  group_by(Participant,variable) %>%
  transform(value = scale(value))

# calculate difference of means and medians 
data.summary <- data %>% group_by(Participant,variable,BlockType) %>%
  summarize(mean = mean(value),median=median(value))

# compute effect sizes
Concha30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Concha30Hz-1'] - data.summary$mean[data.summary$BlockType=='Baseline']
Concha30Hz1_median <- data.summary$median[data.summary$BlockType=='Concha30Hz-1'] - data.summary$median[data.summary$BlockType=='Baseline']
Concha30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Concha30Hz-2'] - data.summary$mean[data.summary$BlockType=='Washout1']
Concha30Hz2_median <- data.summary$median[data.summary$BlockType=='Concha30Hz-2'] - data.summary$median[data.summary$BlockType=='Washout1']
Canal30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Canal30Hz-1'] - data.summary$mean[data.summary$BlockType=='Washout2']
Canal30Hz1_median <- data.summary$median[data.summary$BlockType=='Canal30Hz-1'] - data.summary$median[data.summary$BlockType=='Washout2']
Canal30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Canal30Hz-2'] - data.summary$mean[data.summary$BlockType=='Washout3']
Canal30Hz2_median <- data.summary$median[data.summary$BlockType=='Canal30Hz-2'] - data.summary$median[data.summary$BlockType=='Washout3']

# calculate difference of means and medians 
data.summary <- data %>% group_by(Participant,variable) %>% summarise()
data.summary$Concha30Hz1_mean <- Concha30Hz1_mean
data.summary$Concha30Hz1_median <- Concha30Hz1_median
data.summary$Concha30Hz2_mean <- Concha30Hz2_mean
data.summary$Concha30Hz2_median <- Concha30Hz2_median
data.summary$Canal30Hz1_mean <- Canal30Hz1_mean
data.summary$Canal30Hz1_median <- Canal30Hz1_median
data.summary$Canal30Hz2_mean <- Canal30Hz2_mean
data.summary$Canal30Hz2_median <- Canal30Hz2_median

# re-melt data
data.summary <- melt(as.data.frame(data.summary),id=c('Participant','variable'))
names(data.summary) <- c('Participant','Variable','Effect','Value')


data.summary$Effect <- factor(data.summary$Effect,levels = c("Concha30Hz1_mean", "Concha30Hz1_median", "Concha30Hz2_mean", 
                                                             "Concha30Hz2_median", "Canal30Hz1_mean", "Canal30Hz1_median", 
                                                             "Canal30Hz2_mean", "Canal30Hz2_median"))

# plot difference in effect sizes

data.summary %>% ggplot(aes(x=Effect,y=Value))+
  geom_boxplot()+
  geom_point(aes(x=Effect,y=Value,color=Participant))+
  geom_hline(yintercept=0)+
  facet_wrap('Variable',scales='free_y')+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))

data.summary %>% ggplot(aes(x=Effect,y=Value))+
  geom_boxplot()+
  geom_point(aes(x=Effect,y=Value,color=Participant))+
  geom_hline(yintercept=0)+
  facet_wrap('Variable',scales='free_y')+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))


# 
# ####
# 
# # calculate difference of means and medians 
# data.summary <- data %>% group_by(Participant,BlockType) %>%
#   summarize(mean = mean(value,na.rm=T),median=median(value,na.rm=T))
# 
# # compute effect sizes
# Concha30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Concha30Hz-1'] - data.summary$mean[data.summary$BlockType=='Baseline']
# Concha30Hz1_median <- data.summary$median[data.summary$BlockType=='Concha30Hz-1'] - data.summary$median[data.summary$BlockType=='Baseline']
# Concha30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Concha30Hz-2'] - data.summary$mean[data.summary$BlockType=='Washout1']
# Concha30Hz2_median <- data.summary$median[data.summary$BlockType=='Concha30Hz-2'] - data.summary$median[data.summary$BlockType=='Washout1']
# Canal30Hz1_mean <- data.summary$mean[data.summary$BlockType=='Canal30Hz-1'] - data.summary$mean[data.summary$BlockType=='Washout2']
# Canal30Hz1_median <- data.summary$median[data.summary$BlockType=='Canal30Hz-1'] - data.summary$median[data.summary$BlockType=='Washout2']
# Canal30Hz2_mean <- data.summary$mean[data.summary$BlockType=='Canal30Hz-2'] - data.summary$mean[data.summary$BlockType=='Washout3']
# Canal30Hz2_median <- data.summary$median[data.summary$BlockType=='Canal30Hz-2'] - data.summary$median[data.summary$BlockType=='Washout3']
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
#   theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))
# 
# 
# data.summary %>% ggplot(aes(x=Effect,y=Value))+
#   geom_boxplot()+
#   geom_point(aes(x=Effect,y=Value,color=Participant))+
#   geom_hline(yintercept=0)+
#   theme_bw()+
#   theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))
# 
