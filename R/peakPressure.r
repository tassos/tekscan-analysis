require(ggplot2)
require(plyr)
require(grid)
require(xtable)

rm(list=ls())
options("max.print"=300)
pLevel=0.05
phases<-c(0,20,40,60,80,100)

source("directory.r")
source("common.r")
source('LaTeX.r')

load(paste(outdir,'ppArea.RData',sep=''))
load(paste(outdir,'ppTArea.RData',sep=''))
load(paste(outdir,'peakPressureNeutral.RData',sep=''))
load(paste(outdir,'forceArea.RData',sep=''))
outLaTeX<-paste(outdir,"LaTeX/",sep='')
outdir<-paste("~/PhD/Submissions/Journals/Clinical Orthopaedics and Related Research/Figures/",sep='')

# Combining the data frames of the Tibia and Talus pressures and cleaning the bad data points
ppTArea$Case<-"Tekscan Talus"
ppArea<-rbind(ppTArea,ppArea)
ppArea<-ppArea[complete.cases(ppArea),]

# Retaining only the first five measurements for each case and removing the TA measurements
ppS<-ppS[grep('(Trial 01)|(Trial 02)',ppS$Trial),]
ppArea<-ppArea[grep('(Trial 01)|(Trial 02)|(Trial 03)|(Trial 04)|(Trial 05)',ppArea$Trial),]
ppArea<-ppArea[grep('(foot43)|(foot41)',ppArea$Foot, invert=T),]
ppArea<-ppArea[grep('(TAP)|(Tekscan)', ppArea$Case),]

# Adding proper names for the Rows, Columns and Cases
ppArea$Rows<-mapvalues(ppArea$Rows,from=c("-22 to -7","-6 to 9","10 to 25"), to=c("Anterior","Central","Posterior"))
ppArea$Cols<-mapvalues(ppArea$Cols,from=c("-15 to 0","1 to 16"), to=c("Medial","Lateral"))
ppArea$Case<-mapvalues(ppArea$Case,from=c("Tekscan","Tekscan Talus","TAP"), to=c("Native Tibia","Native Talus","TAA Tibia"))

# Spliting the peak pressure in phases of stance phase
ppArea<-splitToPhases(ppArea,phases)
ppArea<-factorise(ppArea)

# Calculating the maximum peak pressure for each Foot, Case, Trial, Area and Phase
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Rows,Cols,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mmppArea<-ddply(mppArea,.(Foot,Case,Rows,Cols,Phase),function(x) data.frame(Value=mean(x$Value)))

# Calculating the maximum peak pressure for each Foot, Case, Trial for the neutral position measurements
mppS <-ddply(subset(ppS,Case!='TA'),.(Foot,Case,Trial), function(x) data.frame(Value=mean(x$Value/1E6)))

# Statistics for detecting significant differences between Native and TAP
wp<-ddply(mmppArea,.(Rows,Cols,Phase), function(x) data.frame(p.value=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$p.value,estimated.difference=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$estimate))
wp$p.star<-ifelse(wp$p.value <=pLevel,"*"," ")

wpf<-ddply(mppArea,.(Foot,Rows,Cols,Phase), function(x) data.frame(p.value=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$p.value,estim=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$estimate))
wpf$p.star<-ifelse(wpf$p.value <=pLevel,"*"," ")
sumwpf<-ddply(wpf,.(Rows,Cols,Phase), function(x) data.frame(sign.inc=nrow(x[x$estim>0 & x$p.value<=pLevel,]),inc=nrow(x[x$estim>0 & x$p.value>pLevel,]),dec=nrow(x[x$estim<=0 & x$p.value>pLevel,]),sign.dec=nrow(x[x$estim<=0 & x$p.value<=pLevel,])))

sumwpf<-merge(wp,sumwpf, intersect(c('Rows','Cols','Phase'),c('Rows','Cols','Phase')))

sumTable<-xtable(sumwpf,caption='Summary of results',digits=4)#,align="rll|l|lcc|cccc")
sumLatex<-print(sumTable,include.rownames=F, print.results=F)
write(insert.headers(sumLatex),paste(outLaTeX,"sumLatex.tex",sep=''))

filename<-paste(outdir,"Area_Time_Talus")
svg(paste(filename,".svg",sep=''))
p<-ggplot(subset(mmppArea, Case=="Native Talus"), aes(Phase, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
	scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase percentage (%)")+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	theme(legend.position = "none")+
	facet_grid(Rows ~ Cols)
print(p)
dev.off()

shell(paste("inkscape.exe -z -w 2000 -e",filename,".png ",filename,".svg"))

svg(paste(outdir,"Area_Time.svg",sep=''), width=8.4)
p<-ggplot(subset(mmppArea, Case!="Native Talus"), aes(Phase, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
	scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase percentage (%)")+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	facet_grid(Rows ~ Cols)
print(p)
dev.off()

mppS$Case<-mapvalues(mppS$Case,from=c("Tekscan","TAP"), to=c("Native Tibia","TAA Tibia"))
svg(paste(outdir,"Neutral_measurements.svg",sep=''), width=12)
p<-ggplot(subset(mppS,Foot!="foot38" & Foot!="foot43"), aes(Foot, Value, fill=Case))+geom_boxplot()+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black'))+
	scale_y_continuous(name="Peak Pressure (MPa)")
print(p)
dev.off()