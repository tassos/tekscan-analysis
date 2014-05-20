require(ggplot2)
require(plyr)
require(R2HTML)
require(grid)
require(Hmisc)

rm(list=ls())
options("max.print"=300)

source("directory.r")

load(paste(outdir,'peakPressure.RData',sep=''))
outdir<-paste(outdir,"Graphs_pPressure/",sep='')

pLevel=0.01

peakPressure$Trial<-factor(peakPressure$Trial)

peakPressure$Phase<-1
phases<-c()
k=''	
for (i in phases){
	peakPressure$Phase<-ifelse(as.numeric(as.character(peakPressure$Percentage)) >i,peakPressure$Phase+1,peakPressure$Phase)
}
peakPressure$Phase<-factor(peakPressure$Phase)

maxpPressure <-ddply(peakPressure,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Max=max(x$Value/1E6)))

p<-ggplot(maxpPressure, aes(Foot, Max, fill=Case))+geom_boxplot()
print(p)

# p<-ggplot(subset(peakPressure,Case=="Tekscan"), aes(Percentage, Value, color=Foot))+geom_line(aes(group=Foot))
# print(p)