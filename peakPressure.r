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

peakPressure$Phase<-1
phases<-c()
k=''	
for (i in phases){
	peakPressure$Phase<-ifelse(as.numeric(as.character(peakPressure$Percentage)) >i,peakPressure$Phase+1,peakPressure$Phase)
}
peakPressure$Phase<-factor(peakPressure$Phase)