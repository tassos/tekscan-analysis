require(ggplot2)
require(plyr)
require(R2HTML)
require(grid)
require(Hmisc)

rm(list=ls())
options("max.print"=300)

source("directory.r")
source("statistics.r")

load(paste(outdir,'peakPressure.RData',sep=''))
load(paste(outdir,'peakL.RData',sep=''))
load(paste(outdir,'ppArea.RData',sep=''))
outdir<-paste(outdir,"Graphs_pPressure/",sep='')

pLevel=0.05

pp<-peakPressure[grep("(foot44)|(foot45)",peakPressure$Foot, invert = T),]
pp<-pp[grep("(Tekscan)|(TAP)",pp$Case),]
pp$Foot<-factor(pp$Foot)

npp<-ddply(pp,.(Foot,Case,Trial,Variable), function(x) normPressure(x))

phases<-c(20,40,60,80)
pp$Phase<-1
ppArea<-splitToPhases(ppArea,phases)
npp<-splitToPhases(npp,phases)

mpp<-ddply(pp,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Value=max(x$Value/1E6), Rows=x$Rows, Cols=x$Cols))

signf<-ddply(mpp,.(Foot,Phase), function(x) data.frame(P=safewilTest(x,"Value","Case","Tekscan","TAP")$p.value, Est=safewilTest(x,"Value","Case","Tekscan","TAP")$estimate))
signf$Bool<-ifelse(signf$P <=pLevel,"*"," ")

dev.new(record=T)
p<-ggplot(mpp, aes(Trial, Value, fill=Case))+geom_line(aes(group=Foot, color=Foot))
p<-p+facet_grid(Case ~ .)
print(p)

p<-ggplot(mppArea, aes(Phase, Value, fill=Case))+geom_boxplot()
p<-p+facet_grid(Rows ~ Cols)
print(p)