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
ppArea<-rbind(ppTArea,ppArea)
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
ppArea<-factorize(ppArea)

# Calculating the maximum peak pressure for each Foot, Case, Trial, Area and Phase
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Rows,Cols,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mmppArea<-ddply(mppArea,.(Foot,Case,Rows,Cols,Phase),function(x) data.frame(Value=mean(x$Value)))

# Statistics for detecting significant differences
wexp<-ddply(mmppArea,.(Case,Rows,Cols,Phase), function(x) safewilTest(x,"Value","Case","Native Tibia","TAP Tibia")$p.value)


# svg(paste(outdir,"Area_Time_Talus.svg",sep=''))
p<-ggplot(mmppArea, aes(Phase, Value, fill=Case))+geom_boxplot()
p<-p+scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase percentage (%)")
p<-p+facet_grid(Rows ~ Cols)
print(p)
# dev.off()

# dev.new()
p<-ggplot(ppArea, aes(Percentage, Value, group=Case, col=Case))
p<-p+stat_summary(fun.data="mean_cl_normal", geom = "smooth", size=1, alpha=0.2, aes(fill=Case))
p<-p+scale_fill_manual(values=c("black","blue","red"))+scale_color_manual(values=c("black","blue","red"))
p<-p+scale_x_discrete(name="Stance Phase (%)", breaks=seq(0,100,10))+scale_y_continuous(name="Peak Pressure (MPa)")
p<-p+facet_grid(Rows ~ Cols)
print(p)
# dev.off()