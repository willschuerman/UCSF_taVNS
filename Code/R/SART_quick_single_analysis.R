library(hablar)
library(stringr)
library(Rmisc)
library(zoo)
library(tidyverse)

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
  # check that idx doesn't cross block boundaries
  while(btrial[idx_start]>btrial[idx]){
    idx_start=idx_start+1
  }
  while(btrial[idx_stop]<btrial[idx]){
    idx_stop=idx_stop-1
  }    
  return(c(idx_start,idx_stop))
}

get_event_matrix <- function(idx_vector,data_vector,btrial){
  event_matrix = matrix(data=NA,nrow=length(idx_vector),ncol=9)
  
  counter <- 1
  for(idx in idx_vector){
    idx_start_stop <- adjust_idx(idx,btrial)
    midx_start <- 5-(idx-idx_start_stop[1])
    midx_stop <- 5+(idx_start_stop[2]-idx)
    event_matrix[counter,midx_start:midx_stop] <- data_vector[idx_start_stop[1]:idx_start_stop[2]]
    counter <- counter+1
  }
  return(event_matrix)
}

calc_event_metrics <- function(accuracy,RT,anticipations,comissions,omissions,btrial){
  matrix_names <- c('t-4','t-3','t-2','t-1','t0','t+1','t+2','t+3','t+4')
  
  # find ids of errors and collect RTs
  error_idx = which(accuracy==0)
  error_RT = get_event_matrix(error_idx,RT,btrial)
  event_data <- data.frame(error_RT)
  names(event_data) <- matrix_names
  event_data <- reshape2::melt(event_data)
  event_data$type <- 'error'
  
  # find ids of anticipations and collect RTs
  anticipations_idx = which(anticipations==1)
  ant_RT = get_event_matrix(anticipations_idx,RT,btrial)
  tmp <- data.frame(ant_RT)
  names(tmp) <- matrix_names
  tmp <- reshape2::melt(tmp)
  tmp$type <- 'anticipation'
  event_data <- rbind(event_data,tmp)
  
  # find ids of comissions and collect RTs
  comissions_idx = which(comissions==1)
  com_RT = get_event_matrix(comissions_idx,RT,btrial)
  tmp <- data.frame(com_RT)
  names(tmp) <- matrix_names
  tmp <- reshape2::melt(tmp)
  tmp$type <- 'comission'
  event_data <- rbind(event_data,tmp)
  
  # find ids of omissions and collect RTs
  omissions_idx = which(omissions==1)
  om_RT = get_event_matrix(omissions_idx,RT,btrial)
  tmp <- data.frame(om_RT)
  names(tmp) <- matrix_names
  tmp <- reshape2::melt(tmp)
  tmp$type <- 'omission'
  event_data <- rbind(event_data,tmp)
  
  # clean up data frame
  names(event_data) <- c('time','RT','type')
  event_data$time <- factor(event_data$time,levels = matrix_names)
  return(event_data)
}

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

# create trial number within block variable
data <- data %>% group_by(blocknum) %>% mutate(btrial = row_number())

#### Compute additional metrics ####

# 1. Accuracy 

# 1.1 Errors of commission (failure to withhold a response to target)
data$commission_error <- ifelse(data$trialcode=='go',0,
                                ifelse(data$correct==0,1,0))
# 1.2 Errors of omission (failure to respond to non-target)
data$ommission_error <- ifelse(data$trialcode=='nogo',0,
                               ifelse(data$correct==0,1,0))

# 2. Speed / Efficiency of processing

# 2.1. Percentage anticipations (RT < 100ms) (Cheyne et al., 2009)
data$anticipation <- ifelse(data$values.RT<100 & data$values.RT>0,1,0)

# 2.2 Lag RT (average of 8 trials surrounding anticipation or omission)
data <- data %>% group_by(blocknum) %>%
  mutate(rollingmean = rollmean(values.RT,k=9,fill=NA))


# 3. Summary stats

# 3.1 Event related metrics
event_data <- calc_event_metrics(data$correct,data$values.RT,
                                 data$anticipation,data$commission_error,
                                 data$ommission_error,data$btrial)

# 3.1 Accuracy summary (D-prime and A-prime)
accuracy.summary <- data %>% group_by(blocknum) %>%
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


RT.summary <-data %>%
  group_by(blocknum) %>%
  summarize(RT = mean(values.RT), 
            RTcorrect = mean(values.RT[correct==1]),
            RTincorrect = mean(values.RT[correct==1]),
            RTtargets = mean(values.RT[trialcode=='nogo']),
            RTdistractors = mean(values.RT[trialcode=='go']))



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

