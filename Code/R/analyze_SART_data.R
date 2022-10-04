# Analyze SART data

library(tidyverse)



data_dir <- getwd()
data_dir <- sub('/Code/R','/Data/SART_Tests',data_dir)
file_names <- list.files(path=data_dir,pattern='*expr.csv') # exclude practice

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

data$values.amp[data$values.dostim==0] <- 0

data %>% ggplot(aes(x=trialnum,y=latency,color=values.responsetype))+
  geom_point()+facet_wrap(c('blocknum'))
