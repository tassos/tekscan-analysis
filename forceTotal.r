require(ggplot2)
require(plyr)
require(R2HTML)
require(grid)
require(Hmisc)

rm(list=ls())
options("max.print"=300)

source("directory.r")

load(paste(outdir,'force.RData',sep=''))
outdir<-paste(outdir,"Graphs_pPressure/",sep='')

pLevel=0.01

force<-force[grep("(Trial 01|Trial 02)",force$Trial),]
force$Trial<-factor(force$Trial)

force$Phase<-1
phases<-c()
k=''	
for (i in phases){
	force$Phase<-ifelse(as.numeric(as.character(force$Percentage)) >i,force$Phase+1,force$Phase)
}
force$Phase<-factor(force$Phase)

maxpPressure <-ddply(force,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Mean=mean(x$Value)))

p<-ggplot(maxpPressure, aes(Foot, Mean, fill=Case))+geom_boxplot()
print(p)

# p<-ggplot(subset(force,Case=="Tekscan"), aes(Percentage, Value, color=Foot))+geom_line(aes(group=Foot))
# print(p)