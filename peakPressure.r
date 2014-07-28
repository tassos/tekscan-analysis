require(ggplot2)
require(plyr)
require(grid)

rm(list=ls())
options("max.print"=300)

source("directory.r")
source("statistics.r")

load(paste(outdir,'peakPressure.RData',sep=''))
load(paste(outdir,'ppArea.RData',sep=''))
load(paste(outdir,'ppTArea.RData',sep=''))
outdir<-paste(outdir,"Graphs_dPress/",sep='')

pLevel=0.05
phases<-c()

# ppArea<-ppArea[grep('(Trial 01)|(Trial 02)|(Trial 03)|(Trial 04)',ppArea$Trial),]
# ppArea<-ppArea[grep('(foot37)|(foot38)',ppArea$Foot, invert=T),]
ppArea<-ppArea[grep('(Tekscan)|(TAP)',ppArea$Case),]

ppArea<-splitToPhases(ppArea,phases)
ppTArea<-splitToPhases(ppTArea,phases)

mpp<-ddply(ppArea,.(Foot,Case,Trial,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mppT<-ddply(ppTArea,.(Foot,Case,Trial,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Value=max(x$Value/1E6), Rows=x$Rows, Cols=x$Cols))
mppTArea<-ddply(ppTArea,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Value=max(x$Value/1E6), Rows=x$Rows, Cols=x$Cols))

# svg(paste(outdir,"Area_Time_Talus.svg",sep=''))
# p<-ggplot(mppTArea, aes(Phase, Value, fill=Case))+geom_boxplot()
# p<-p+facet_grid(Rows ~ Cols)
# print(p)
# dev.off()

p<-ggplot(mppArea, aes(Foot, Value, fill=Case))+geom_boxplot()
p<-p+scale_y_continuous(name="Peak Pressure (MPa)", breaks=seq(0,15,2.5))
p<-p+facet_grid(Rows ~ Cols)
print(p)

# dev.new()
# p<-ggplot(ppArea, aes(Percentage, Value, group=Case, col=Case))
# p<-p+stat_summary(fun.data="mean_cl_normal", geom = "smooth", size=1, alpha=0.2, aes(fill=Case))
# p<-p+scale_fill_manual(values=c("black","blue","red","green3"))+scale_color_manual(values=c("black","blue","red","green3"))
# p<-p+scale_x_discrete(name="Stance Phase (%)", breaks=seq(0,100,10))
# p<-p+facet_grid(Rows ~ Cols)
# print(p)
