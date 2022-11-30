library(hablar)
library(stringr)
library(Rmisc)
library(zoo)
library(tidyverse)
myPalette <- c("#8961b3","#b55960","#999c47")


# define custom functions
adjust_idx <- function(idx,btrial){
  # check that idx isn't greater than limits of vector
  idx_start = idx-4
  if(idx_start<1){
    idx_start = 1
  }
  idx_stop = idx+4
  if(idx_stop>length(btrial)){
    idx_stop=length(btrial)
  }
  # # check that idx doesn't cross block boundaries (changed to looping over blocks)
  # while(btrial[idx_start]>btrial[idx]){
  #   idx_start=idx_start+1
  # }
  # while(btrial[idx_stop]<btrial[idx]){
  #   idx_stop=idx_stop-1
  # }    
  return(c(idx_start,idx_stop))
}

get_event_matrix <- function(idx_vector,data_vector,btrial){
  event_matrix = matrix(data=NA,nrow=length(idx_vector),ncol=9)
  
  counter <- 1
  for(idx in idx_vector){
    idx_start_stop <- adjust_idx(idx,btrial)
    midx_start <- 5-(idx-idx_start_stop[1])
    midx_stop <- 5+(idx_start_stop[2]-idx)
    event_matrix[counter,seq(midx_start,midx_stop)] <- data_vector[seq(idx_start_stop[1],idx_start_stop[2])]
    counter <- counter+1
  }
  return(event_matrix)
}

make_event_df <- function(idx,RT,btrial,matrix_names,event_type){
  if(!is_empty(idx)){
    RT = get_event_matrix(idx,RT,btrial)
    event_df <- data.frame(RT)
    names(event_df) <- matrix_names
    event_df <- reshape2::melt(event_df)
    event_df$type <- event_type
  }else{
    event_df <- data.frame(matrix(ncol=3,nrow=0))
    names(event_df) <- c('variable','value','type')
  }
  return(event_df)
}

# need to add block ids
calc_event_metrics <- function(accuracy,RT,anticipations,commissions,omissions,btrial,trialcode){
  matrix_names <- c('t-4','t-3','t-2','t-1','t0','t+1','t+2','t+3','t+4')

  # find ids of errors and collect RTs
  idx = which(accuracy==0)
  event_data <-  make_event_df(idx,RT,btrial,matrix_names,'error')
  
  # find ids of correct trials and collect RTs
  idx = which(accuracy==1)
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'correct')
  event_data <- rbind(event_data,tmp)
  
  # find ids of go trials and collect RTs
  idx = which(trialcode=='go')
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'go')
  event_data <- rbind(event_data,tmp)
  
  # find ids of anticipations and collect RTs
  idx = which(trialcode=='nogo')
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'nogo')
  event_data <- rbind(event_data,tmp)
  
  # find ids of anticipations and collect RTs
  idx = which(anticipations==1)
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'anticipation')
  event_data <- rbind(event_data,tmp)
  
  # find ids of commissions and collect RTs
  idx = which(commissions==1)
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'commission')
  event_data <- rbind(event_data,tmp)
  
  # find ids of omissions and collect RTs
  idx = which(omissions==1)
  tmp <-  make_event_df(idx,RT,btrial,matrix_names,'omission')
  event_data <- rbind(event_data,tmp)
  
  # clean up data frame
  names(event_data) <- c('time','RT','type')
  event_data$time <- factor(event_data$time,levels = matrix_names)
  return(event_data)
}


data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/SART_Microstudy/Behavior/',data_dir)

file_names <- list.files(path=data_dir,pattern='*.csv')

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
  tmp$filename <- f
  if(make_table==1){
    data <- tmp
    make_table=0
  }else{
    data <- rbind(data,tmp)
  }
}

# fix PID for first participant
data[data$subject==101,]$subject <- 501

# create trial number within block variable
data <- data %>% group_by(subject,blocknum) %>% mutate(btrial = row_number())

# change variables to factors
data$stimblock <- as.factor(data$stimblock)
data$subject <- as.factor(data$subject)


#### Visualize raw RT data ####

# ggplot(data,aes(x=values.RT,fill=subject))+
#   geom_histogram()+
#   facet_wrap(c('subject'))+
#   scale_fill_discrete(name = '',labels=c('New RT logger','Old RT Logger'))+
#   ggpubr::theme_pubclean()+
#   xlab('Reaction Time (ms)')+
#   ylab('Count')


#### Compute additional metrics ####

# 1. Accuracy 

# 1.1 Errors of commission (failure to withhold a response to target)
data$commission_error <- ifelse(data$trialcode=='go',0,
                                ifelse(data$correct==0,1,0))
# 1.2 Errors of omission (failure to respond to non-target)
data$omission_error <- ifelse(data$trialcode=='nogo',0,
                               ifelse(data$correct==0,1,0))

# 2. Speed / Efficiency of processing

# 2.1. Percentage anticipations (RT < 100ms) (Cheyne et al., 2009)
data$anticipation <- ifelse(data$values.RT<100 & data$values.RT>0,1,0)

# 2.2 Lag RT (average of 8 trials surrounding anticipation or omission)
data <- data %>% group_by(blocknum) %>%
  mutate(rollingmean = rollmean(values.RT,k=9,fill=NA))

# 3. Summary stats

# 3.1 Event related metrics
make_df <- 1
for(s in unique(data$subject)){
  for(b in unique(data$blocknum)){
    data_in <- data[data$blocknum==b & data$subject==s,]
    tmp <- calc_event_metrics(data_in$correct,data_in$values.RT,
                              data_in$anticipation,
                              data_in$commission_error,
                              data_in$omission_error,
                              data_in$btrial,
                              data_in$trialcode)
    tmp$blocknum <- b
    tmp$subject <- s
    if(make_df){
      event_data <- tmp
      make_df <- 0
    }else{
      event_data <- rbind(event_data,tmp)
    }
  }
}

event_data <- merge(event_data,unique(data[,c('blocknum','stimblock')]),by='blocknum')

# 3.1 Accuracy summary (D-prime and A-prime)
accuracy.summary <- data %>% group_by(subject,blocknum) %>%
  summarize(hits = sum(correct[trialcode=='nogo']),
            misses = sum(correct[trialcode=='nogo']==0),
            false_alarms = sum(correct[trialcode=='go']==0),
            correct_rejections = sum(correct[trialcode=='go']),
            n_targets = hits+misses,
            n_distractors = false_alarms + correct_rejections,
            total = n_targets + n_distractors,
            hit_rate = hits / n_targets,
            miss_rate = misses / n_targets,
            fa_rate = false_alarms / n_distractors,
            hit_rate_adjusted = (hits + 0.5)/(hits + misses + 1),
            fa_rate_adjusted = (false_alarms + 0.5)/(false_alarms + correct_rejections + 1),
            dprime = qnorm(hit_rate) - qnorm(miss_rate),
            dprime_adjusted = qnorm(hit_rate_adjusted) - qnorm(fa_rate_adjusted))

# aprime
a <- 1 / 2 + ((accuracy.summary$hit_rate - accuracy.summary$fa_rate) * (1 + accuracy.summary$hit_rate - accuracy.summary$fa_rate) / (4 * accuracy.summary$hit_rate * (1 - accuracy.summary$fa_rate)))
b <- 1 / 2 - ((accuracy.summary$fa_rate - accuracy.summary$hit_rate) * (1 + accuracy.summary$fa_rate - accuracy.summary$hit_rate) / (4 * accuracy.summary$fa_rate * (1 - accuracy.summary$hit_rate)))

# Store possible missing values due to absence of targets / distractors
ok <- !(is.na(a) | is.na(b))

a[ok][accuracy.summary$fa_rate[ok] > accuracy.summary$hit_rate[ok]] <- b[ok][accuracy.summary$fa_rate[ok] > accuracy.summary$hit_rate[ok]]
a[ok][accuracy.summary$fa_rate[ok] == accuracy.summary$hit_rate[ok]] <- .5
accuracy.summary$aprime <- a
accuracy.summary <- reshape2::melt(accuracy.summary,id.vars=c('subject','blocknum'))
accuracy.summary <- merge(accuracy.summary,unique(data[,c('subject','blocknum','stimblock')]),by=c('subject','blocknum'))

RT.summary <-data %>%
  group_by(subject,blocknum) %>%
  summarize(RT = mean(values.RT), 
            RTcorrect = mean(values.RT[correct==1]),
            RTincorrect = mean(values.RT[correct==1]),
            RTtargets = mean(values.RT[trialcode=='nogo']),
            RTdistractors = mean(values.RT[trialcode=='go']))


#### visualize summary metrics ####

ggplot(accuracy.summary[accuracy.summary$blocknum>0 & 
                          accuracy.summary$variable %in%
                          c("n_targets","n_distractors",'total'),],
       aes(x=blocknum,y=value,fill=variable))+
  geom_bar(stat='identity',position=position_dodge())+
  ggpubr::theme_pubclean()+
  scale_fill_viridis_d(end=0.8,labels=c('NOGO', 'GO', 'Total'),
                       name='Trial Type')+
  xlab("Block")+
  ylab("Count")


ggplot(accuracy.summary[accuracy.summary$blocknum>0 & 
                          accuracy.summary$variable %in%
                          c("hits", "misses", "false_alarms", 
                            "correct_rejections","hit_rate", "miss_rate", 
                            "fa_rate", "hit_rate_adjusted", "fa_rate_adjusted", 
                            "dprime", "dprime_adjusted", "aprime"),],
       aes(x=blocknum,y=value,color=stimblock,group=subject,shape=subject))+
  geom_point()+
  geom_line()+
  facet_wrap('variable',scales='free')+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)


#### visualize event-related metrics ####

d <- summarySE(event_data,measurevar='RT',groupvars=c('time','type','stimblock','subject'),na.rm=T)
d$type <- as.factor(d$type)
levels(d$type) <- c("anticipation errors", "commission errors", "correct", 
                    "all errors", "go trial", "nogo trial", "omission error")
d$type <- relevel(d$type,'omission error')
d$type <- relevel(d$type,'all errors')

ggplot(d,aes(x=time,y=RT,color=stimblock,group=stimblock))+
  geom_vline(xintercept='t0')+
  geom_point()+
  geom_errorbar(aes(ymin=RT-ci,ymax=RT+ci),width=0.2)+
  geom_line()+
  facet_grid(subject~type,scales='free')+
  ggpubr::theme_pubr()+
  scale_color_manual(values=myPalette)


#### visualize raw metrics ####

d <- summarySE(data[data$blocknum>0,],measurevar='values.RT',groupvars=c('blocknum','stimblock','subject'))
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=values.RT,shape=stimblock,color=subject,group=subject))+
  geom_point(size=3)+
  geom_line()+
  geom_errorbar(aes(ymin=values.RT-ci,ymax=values.RT+ci),width=0.1)+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)

d <- summarySE(data[data$blocknum>0,],measurevar='values.RT',groupvars=c('blocknum','stimblock','subject','trialcode'))
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=values.RT,color=stimblock,group=trialcode,shape=trialcode))+
  geom_point(size=3,position=position_dodge(0.3))+
  geom_errorbar(aes(ymin=values.RT-ci,ymax=values.RT+ci),width=0.1,
                position=position_dodge(0.3))+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette)+
  facet_wrap('subject')+
  ylab('Reaction Time (ms)')



d <- summarySE(data[data$blocknum>0,],measurevar='correct',groupvars=c('blocknum','stimblock','trialcode','subject'))
ggplot(d[d$blocknum>0,],aes(x=blocknum,y=correct,color=stimblock,group=trialcode,shape=trialcode))+
  geom_point(size=3,position=position_dodge(0.3))+
  geom_errorbar(aes(ymin=correct-ci,ymax=correct+ci),width=0.1,
                position=position_dodge(0.3))+
  ggpubr::theme_pubclean()+
  scale_color_manual(values=myPalette,name='tVNS',labels=c('sham','stim'))+
  scale_shape_manual(values=c(19,17),name='Trial Type')+
  facet_wrap('subject')+
  ylab('Accuracy')+
  xlab('Block Number')


d <- as.data.frame(with(data[data$subject=='501',],xtabs(~values.responsetype+blocknum)))
d$subject = '501'
tmp <- as.data.frame(with(data[data$subject=='502',],xtabs(~values.responsetype+blocknum)))
tmp$subject = '502'
d <- rbind(d,tmp)


ggplot(d[d$blocknum!=0,],aes(y=Freq,x=blocknum,fill=values.responsetype))+
  geom_bar(stat='identity',position=position_dodge(),color='black')+
  facet_wrap(c('subject'))+
  ggpubr::theme_pubclean()+
  scale_fill_discrete(name='Respone Type')+
  #scale_shape_manual(values=c(19,17),name='Trial Type')+
  ylab('Count')+
  xlab('Block Number')

ggplot(data[data$blockcode=='SART',],aes(x=values.RT))+
  geom_histogram(binwidth=30)+
  facet_grid(subject~.,scales='free')+
  ggpubr::theme_pubclean()


