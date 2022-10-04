library(readxl)
library(stringr)
library(hablar)
library(reshape)
library(Hmisc)
library(tidyverse)
library(broom)

# define custom color palette
myPalette <- c("#8961b3","#b55960","#999c47")


data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/Physiology_Tests/September_Physio_Tests/',data_dir)

file_names <- list.files(path=data_dir,pattern='*.csv')

# prepare data
make_table <- 1
for(f in file_names){
  tmp <- read_csv(str_c(data_dir,'/',f))
  if(make_table==1){
    data <- tmp
    make_table=0
  }else{
    data <- rbind(data,tmp)
  }
}

data <- data %>% filter(Minute!=0,Block!=0)
data$PID <- as.factor(data$PID)

# add IBI as the average difference within a 10 second window (not rolling)
data$SecondInterval <- ceil(data$Second/10)
data$SecondInterval[data$SecondInterval==0] <- 1
data$SecondInterval <- as.factor(data$SecondInterval)

data <- data %>%
  group_by(PID,Minute,Block,SecondInterval) %>%
  mutate(IBI = mean(diff(Second))) %>%
  ungroup()

# melt data
data <- data %>% pivot_longer(cols=c('Current','QRSduration','Ramplitude','Rwavepeaktime','IBI'),names_to='Variable',values_to='Value')

# detect outliers
data <- data %>%
  group_by(PID, Variable) %>%
  mutate(cValue = scale(Value,scale=FALSE)[,1],zValue=scale(Value)[,1]) %>% ungroup()
data$isOutlier <- ifelse(abs(data$zValue) > 5,1,0)
data$isOutlier[data$Variable=='Current'] <- 0

# add information about each block
concha_then_canal <- c('CR','PH','MQ','QG')
canal_then_concha <- c('IG','AP')
sham <- c('DL','JL')

data$Group <- ifelse(data$PID %in% concha_then_canal,'Concha-then-Canal',
                     ifelse(data$PID %in% canal_then_concha,'Canal-then-Concha','Sham-Sham'))
data$Gender <- ifelse(data$PID %in% c('CR','IG','DL','JL'),'Female','Male')


data$BlockName <- ''
data[data$Block==1,]$BlockName <- 'Baseline'
data[data$Block==2,]$BlockName <- 'StimA1'
data[data$Block==3,]$BlockName<- 'Rest1'
data[data$Block==4,]$BlockName <- 'StimA2'
data[data$Block==5,]$BlockName <- 'Rest2'
data[data$Block==6,]$BlockName <- 'StimB1'
data[data$Block==7,]$BlockName <- 'Rest3'
data[data$Block==8,]$BlockName <- 'StimB2'
data$BlockName <- factor(data$BlockName, levels=c('Baseline','StimA1','Rest1',
                                                  'StimA2','Rest2','StimB1',
                                                  'Rest3','StimB2'))
data$BlockType <- ''
data[data$Block==1,]$BlockType <- 'Baseline'
data[data$Block==2,]$BlockType <- with(data[data$Block==2,],ifelse(PID %in% concha_then_canal,'Concha',
                               ifelse(PID %in% canal_then_concha,'Canal','Sham')))

data[data$Block==3,]$BlockType<- 'Rest'

data[data$Block==4,]$BlockType <- with(data[data$Block==4,],ifelse(PID %in% concha_then_canal,'Concha',
                                                                   ifelse(PID %in% canal_then_concha,'Canal','Sham')))
data[data$Block==5,]$BlockType <- 'Rest'

data[data$Block==6,]$BlockType <- with(data[data$Block==6,],ifelse(PID %in% concha_then_canal,'Canal',
                                                                   ifelse(PID %in% canal_then_concha,'Concha','Sham')))
data[data$Block==7,]$BlockType <- 'Rest'

data[data$Block==8,]$BlockType <- with(data[data$Block==8,],ifelse(PID %in% concha_then_canal,'Canal',
                                                                   ifelse(PID %in% canal_then_concha,'Concha','Sham')))

data$BlockType <- factor(data$BlockType,levels=c('Baseline','Rest','Concha','Canal','Sham'))


# center and normalize to baseline
for(p in unique(data$PID)){
  for(v in unique(data$Variable)){
    data[data$PID==p & data$Variable==v,]$Second = data[data$PID==p & data$Variable==v,]$Second - min(data[data$PID==p & data$Variable==v,]$Second)
    base_mean = mean(data[data$PID==p & data$Variable==v & data$BlockType=='Baseline',]$Value,na.rm=T)
    base_std = sd(data[data$PID==p & data$Variable==v & data$BlockType=='Baseline',]$Value,na.rm=T)
    data[data$PID==p & data$Variable==v,]$cValue <- (data[data$PID==p & data$Variable==v,]$Value - base_mean)
    data[data$PID==p & data$Variable==v,]$zValue <- (data[data$PID==p & data$Variable==v,]$Value - base_mean)/base_std
  }
}

# Fix sham data
data <- data %>%
  mutate(Value = case_when(Variable=='Current' & Group=='Sham-Sham'~0,TRUE~Value))
data$zValue[data$Variable=='Current'] <- data$Value[data$Variable=='Current']


data %>% filter(isOutlier==0,Variable!='Current') %>%
  ggplot(aes(x=zValue,fill=PID))+
  geom_histogram()+
  facet_wrap(c('Variable'),scales='free')+
  ggpubr::theme_pubclean()

data.summary <- data %>% filter(isOutlier==0) %>% 
  select(BlockType,Variable,zValue) %>%
  group_by(Variable,BlockType) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=BlockType,y=Mean,group=''))+
  geom_line()+
  geom_errorbar(aes(ymin=Lower,ymax=Upper))+
  facet_wrap(c('Variable'),scales='free')+
  ggpubr::theme_pubclean()

data.summary <- data %>% filter(isOutlier==0) %>% 
  select(Group,BlockName,Variable,zValue) %>%
  group_by(Variable,Group,BlockName) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)
data.summary<- droplevels(data.summary)

data.summary %>% ggplot(aes(x=BlockName,y=Mean,color=Group,group=Group))+
  geom_hline(yintercept=0)+
  geom_line()+
  geom_point()+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap(c('Variable'),scales='free')+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)

data.summary <- data %>% filter(isOutlier==0) %>% 
  select(Group,PID,BlockName,Variable,Gender,zValue) %>%
  group_by(PID,Variable,Group,Gender,BlockName) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)
data.summary<- droplevels(data.summary)

data.summary %>% ggplot(aes(x=BlockName,y=Mean,color=PID,group=PID))+
  geom_line()+
  geom_point()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_grid(Variable~Group,scales='free')+
  ggpubr::theme_pubclean()

#### Temporal Analyses ####

# regressing out RR from QRS duration
# https://www.sciencedirect.com/science/article/pii/S0022073618308008?casa_token=_z27BpzA5QMAAAAA:LcIVvfkx9mdMYlqRr4I6VSWfrWuq4oqvYIEaaErWE2RtIDCMPJtdddKYtzxXwdg5J6xs8bO_yw#bb0005

tmp <- data %>%
  filter(PID=='JL', Variable %in% c('IBI','QRSduration'),isOutlier==0) %>%
  group_by(SecondInterval,Variable) %>%
  summarize(Mean=mean(zValue,na.rm=T)) %>% 
  pivot_wider(id_cols='SecondInterval',names_from='Variable',values_from = 'Mean') %>%
  ungroup()

lm.mod <- lm(QRSduration~1+IBI,data=tmp)  
summary(lm.mod)

ggplot(tmp,aes(x=IBI,y=QRSduration))+
  geom_point()+
  geom_smooth(method='lm',se = FALSE)

tmp$QRSc <- resid(lm.mod)

ggplot(tmp,aes(x=IBI,y=QRSc))+
  geom_point()+
  geom_smooth(method='lm',se = FALSE)


tmp <- data %>%
  filter(Variable %in% c('IBI','QRSduration'),isOutlier==0) %>%
  group_by(PID,SecondInterval,Variable) %>%
  summarize(Mean=mean(zValue,na.rm=T)) %>% 
  pivot_wider(id_cols=c('PID','SecondInterval'),names_from='Variable',values_from = 'Mean') %>%
  ungroup() %>% 
  group_by(PID) %>%
  do(augment(lm(QRSduration ~ IBI, data=.))) %>%
  select(PID,QRSduration,IBI,.resid) %>%
  rename(QRSc = .resid) %>%
  ungroup()
  
tmp2 <- data %>%
  filter(Variable %in% c('IBI','QRSduration'),isOutlier==0) %>%
  group_by(PID,SecondInterval,Variable) %>% 
  summarize(Mean=mean(zValue,na.rm=T))  %>%
  pivot_wider(id_cols=c('PID','SecondInterval'),names_from='Variable',values_from = 'Mean') %>%
  ungroup()

tmp <- inner_join(tmp,tmp2)

tmp <- inner_join(tmp,data %>% select(PID,SecondInterval,Minute,Block,BlockType,BlockName,Group,Gender) %>%
                    distinct())

tmp <- tmp %>% pivot_longer(cols=c('QRSduration','IBI','QRSc'),names_to='Variable',values_to='zValue')

data.summary <- tmp %>%
  select(BlockType,Variable,zValue) %>%
  group_by(Variable,BlockType) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)

data.summary %>% ggplot(aes(x=BlockType,y=Mean,group=''))+
  geom_line()+
  geom_errorbar(aes(ymin=Lower,ymax=Upper))+
  facet_wrap(c('Variable'),scales='free')+
  ggpubr::theme_pubclean()

data.summary <- tmp %>% 
  select(Group,BlockName,Variable,zValue) %>%
  group_by(Variable,Group,BlockName) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)
data.summary<- droplevels(data.summary)

data.summary %>% ggplot(aes(x=BlockName,y=Mean,color=Group,group=Group))+
  geom_line()+
  geom_point()+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_wrap(c('Variable'),scales='free')+
  ggpubr::theme_pubclean()

data.summary <- tmp %>% 
  select(Group,PID,BlockName,Variable,Gender,zValue) %>%
  group_by(PID,Variable,Group,Gender,BlockName) %>%
  summarise(data = list(smean.cl.boot(cur_data(), conf.int = .95, B = 1000, na.rm = TRUE))) %>%
  tidyr::unnest_wider(data)
data.summary<- droplevels(data.summary)

data.summary %>% ggplot(aes(x=BlockName,y=Mean,color=PID,group=PID))+
  geom_line()+
  geom_point()+
  geom_hline(yintercept=0)+
  geom_errorbar(aes(ymin=Lower,ymax=Upper),width=0.1)+
  facet_grid(Variable~Group,scales='free')+
  ggpubr::theme_pubclean()
