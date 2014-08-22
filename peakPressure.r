require(ggplot2)
require(plyr)
require(grid)

rm(list=ls())
options("max.print"=300)
pLevel=0.05
phases<-c(0,20,40,60,80,100)

source("directory.r")
source("common.r")

load(paste(outdir,'ppArea.RData',sep=''))
load(paste(outdir,'ppTArea.RData',sep=''))
outdir<-paste(outdir,"Graphs_dPress/",sep='')

# Combining the data frames of the Tibia and Talus pressures and cleaning the bad data points
ppTArea$Case<-"Tekscan Talus"
# ppArea<-rbind(ppTArea,ppArea)
ppArea<-ppArea[complete.cases(ppArea),]

# Retaining only the first five measurements for each case and removing the TA measurements
ppArea<-ppArea[grep('(Trial 01)|(Trial 02)|(Trial 03)|(Trial 04)|(Trial 05)',ppArea$Trial),]
ppArea<-ppArea[grep('(TAP)|(Tekscan)', ppArea$Case),]

# Adding proper names for the Rows, Columns and Cases
ppArea$Rows<-mapvalues(ppArea$Rows,from=c("-22 to -7","-6 to 9","10 to 25"), to=c("Anterior","Central","Posterior"))
ppArea$Cols<-mapvalues(ppArea$Cols,from=c("-15 to 0","1 to 16"), to=c("Medial","Lateral"))
ppArea$Case<-mapvalues(ppArea$Case,from=c("Tekscan","Tekscan Talus","TAP"), to=c("Native Tibia","Native Talus","TAP Tibia"))

# Spliting the peak pressure in phases of stance phase
ppArea<-splitToPhases(ppArea,phases)
ppArea<-factorise(ppArea)

# Calculating the maximum peak pressure for each Foot, Case, Trial, Area and Phase
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Rows,Cols,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mmppArea<-ddply(mppArea,.(Foot,Case,Rows,Cols,Phase),function(x) data.frame(Value=mean(x$Value)))

mmppArea$Variable<-paste(mmppArea$Rows,mmppArea$Cols,sep='-')
summmppArea<-summarySE(mmppArea,measurevar="Value", groupvars=c("Case","Rows","Cols","Phase"))

# Statistics for detecting significant differences between Native and TAP
wp<-ddply(mmppArea,.(Rows,Cols,Phase), function(x) data.frame(p.value=safewilTest(x,"Value","Case","Native Tibia","TAP Tibia")$p.value))
wp$p.star<-ifelse(wp$p.value <=pLevel,"*"," ")

# svg(paste(outdir,"Area_Time_Talus.svg",sep=''))
p<-ggplot(summmppArea, aes(Phase, Value, fill=Case))+geom_bar(stat="identity", position="dodge")
p<-p+geom_errorbar(aes(ymin=Value-se,ymax=Value+se),width=.2,position=position_dodge(.9))
p<-p+scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase percentage (%)")
p<-p+facet_grid(Rows ~ Cols)
print(p)
# dev.off()