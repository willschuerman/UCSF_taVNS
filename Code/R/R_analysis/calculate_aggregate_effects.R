library(tidyverse)
library(readxl)
library(stringr)
library(hablar)
library(reshape)

data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/Physiology_Tests',data_dir)

file_names <- list.files(path=data_dir,pattern='*.xlsx')

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
data$BlockType[data$Minute > 5 & data$Minute<11] <- 'Stim30Hz'
data$BlockType[data$Minute > 10 & data$Minute<16] <- 'Washout1'
data$BlockType[data$Minute > 15 & data$Minute<21] <- 'Stim1kHz'
data$BlockType[data$Minute > 20 & data$Minute<26] <- 'Washout2'
data$BlockType[data$Minute > 25 & data$Minute<31] <- 'Stim30HzIPD500'


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
Stim30Hz_mean <- data.summary$mean[data.summary$BlockType=='Stim30Hz'] - data.summary$mean[data.summary$BlockType=='Baseline']
Stim30Hz_median <- data.summary$median[data.summary$BlockType=='Stim30Hz'] - data.summary$median[data.summary$BlockType=='Baseline']
Stim1kHz_mean <- data.summary$mean[data.summary$BlockType=='Stim1kHz'] - data.summary$mean[data.summary$BlockType=='Washout1']
Stim1kHz_median <- data.summary$median[data.summary$BlockType=='Stim1kHz'] - data.summary$median[data.summary$BlockType=='Washout1']
Stim30HzIPD500_mean <- data.summary$mean[data.summary$BlockType=='Stim30HzIPD500'] - data.summary$mean[data.summary$BlockType=='Washout2']
Stim30HzIPD500_median <- data.summary$median[data.summary$BlockType=='Stim30HzIPD500'] - data.summary$median[data.summary$BlockType=='Washout2']

# calculate difference of means and medians 
data.summary <- data %>% group_by(Participant,variable) %>% summarise()
data.summary$Stim30Hz_mean <- Stim30Hz_mean
data.summary$Stim30Hz_median <- Stim30Hz_median
data.summary$Stim1kHz_mean <- Stim1kHz_mean
data.summary$Stim1kHz_median <- Stim1kHz_median
data.summary$Stim30HzIPD500_mean <- Stim30HzIPD500_mean
data.summary$Stim30HzIPD500_median <- Stim30HzIPD500_median

# re-melt data
data.summary <- melt(as.data.frame(data.summary),id=c('Participant','variable'))
names(data.summary) <- c('Participant','Variable','Effect','Value')


data.summary$Effect <- factor(data.summary$Effect,levels = c("Stim30Hz_mean", "Stim30Hz_median", "Stim1kHz_mean", "Stim1kHz_median", 
                                                                "Stim30HzIPD500_mean", "Stim30HzIPD500_median"))

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
  facet_wrap('Variable')+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))



####

# calculate difference of means and medians 
data.summary <- data %>% group_by(Participant,BlockType) %>%
  summarize(mean = mean(value),median=median(value))

# compute effect sizes
Stim30Hz_mean <- abs(data.summary$mean[data.summary$BlockType=='Stim30Hz'] - data.summary$mean[data.summary$BlockType=='Baseline'])
Stim30Hz_median <- abs(data.summary$median[data.summary$BlockType=='Stim30Hz'] - data.summary$median[data.summary$BlockType=='Baseline'])
Stim1kHz_mean <- abs(data.summary$mean[data.summary$BlockType=='Stim1kHz'] - data.summary$mean[data.summary$BlockType=='Washout1'])
Stim1kHz_median <- abs(data.summary$median[data.summary$BlockType=='Stim1kHz'] - data.summary$median[data.summary$BlockType=='Washout1'])
Stim30HzIPD500_mean <- abs(data.summary$mean[data.summary$BlockType=='Stim30HzIPD500'] - data.summary$mean[data.summary$BlockType=='Washout2'])
Stim30HzIPD500_median <- abs(data.summary$median[data.summary$BlockType=='Stim30HzIPD500'] - data.summary$median[data.summary$BlockType=='Washout2'])

# calculate difference of means and medians 
data.summary <- data %>% group_by(Participant) %>% summarise()
data.summary$Stim30Hz_mean <- Stim30Hz_mean
data.summary$Stim30Hz_median <- Stim30Hz_median
data.summary$Stim1kHz_mean <- Stim1kHz_mean
data.summary$Stim1kHz_median <- Stim1kHz_median
data.summary$Stim30HzIPD500_mean <- Stim30HzIPD500_mean
data.summary$Stim30HzIPD500_median <- Stim30HzIPD500_median

# re-melt data
data.summary <- melt(as.data.frame(data.summary),id=c('Participant'))
names(data.summary) <- c('Participant','Effect','Value')

data.summary$Effect <- factor(data.summary$Effect,levels = c("Stim30Hz_mean", "Stim30Hz_median", "Stim1kHz_mean", "Stim1kHz_median", 
                                                             "Stim30HzIPD500_mean", "Stim30HzIPD500_median"))

data.summary %>% ggplot(aes(x=Effect,y=Value,color=Participant))+
  geom_point()+
  geom_hline(yintercept=0)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))


data.summary %>% ggplot(aes(x=Effect,y=Value))+
  geom_boxplot()+
  geom_point(aes(x=Effect,y=Value,color=Participant))+
  geom_hline(yintercept=0)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust = -0.5, hjust=1))

