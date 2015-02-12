require(ggplot2)
require(plyr)
require(grid)
require(tables)

rm(list=ls())
options("max.print"=300)
pLevel=0.05
phases<-c(0,20,40,60,80,100)

width=500
height=500
res=200

Case1='Case1' #Type the string of the first case that you want to analyse
Case2='Case2' #Type the string of the second case that you want to analyse

source("common.r")

cat(format(Sys.time(), "%H:%M:%S"),'Loading data\n')

indir<-choose.dir(default='',caption='Select folder where the variable files are')
outdirg<-choose.dir(default='',caption='Select output folder for the figures')

load(paste(indir,'\\ppArea.RData',sep=''))
load(paste(indir,'\\peakPressureNeutral.RData',sep=''))

# Combining the data frames of the Tibia and Talus pressures and cleaning the bad data points
ppArea<-ppArea[complete.cases(ppArea),]

cat(format(Sys.time(), "%H:%M:%S"),'Manipulating input data\n')

# Spliting the peak pressure in phases of stance phase
ppArea<-splitToPhases(ppArea,phases)
ppArea<-factorise(ppArea)

cat(format(Sys.time(), "%H:%M:%S"),'Calculating peak pressure measures\n')

# Calculating the maximum peak pressure for each Specimen, Case, Trial, Area and Phase
mppArea<-ddply(ppArea,.(Specimen,Case,Trial,Rows,Cols,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mmppArea<-ddply(mppArea,.(Specimen,Case,Rows,Cols,Phase),function(x) data.frame(Value=mean(x$Value)))
medppArea<-ddply(mmppArea,.(Case,Rows,Cols,Phase), function(x) data.frame(Value=median(x$Value)))

# Calculating the location of the maximum and minumum median peak pressure
medmax<-ddply(medppArea,.(Case,Phase), function(x) x[x$Value==max(x$Value),])
medmin<-ddply(medppArea,.(Case,Phase), function(x) x[x$Value==min(x$Value),])

# Calculating the maximum peak pressure for each Specimen, Case, Trial for the neutral position measurements
mppS <-ddply(ppS,.(Specimen,Case,Trial), function(x) data.frame(Value=max(x$Value/1E6)))
mppS <-ddply(mppS,.(Specimen,Case), function(x) data.frame(Value=mean(x$Value)))

cat(format(Sys.time(), "%H:%M:%S"),'Calculating statistics\n')

# Statistics for detecting significant differences between Case1 and Case2 (dynamic)
wp<-ddply(mmppArea,.(Rows,Cols,Phase), function(x) data.frame(estimated.difference=round(safewilTest(x,"Value","Case",Case1,Case2)$estimate,3),p.value=safewilTest(x,"Value","Case",Case1,Case2)$p.value))
wp$p.value<-ifelse(wp$p.value <=pLevel,paste(round(wp$p.value,3),"(*)"),round(wp$p.value,3))

wpf<-ddply(mppArea,.(Specimen,Rows,Cols,Phase), function(x) data.frame(estim=safewilTest(x,"Value","Case",Case1,Case2)$estimate,p.value=safewilTest(x,"Value","Case",Case1,Case2)$p.value))
wpf$p.star<-ifelse(wpf$p.value <=pLevel,"(*)"," ")
sumwpf<-ddply(wpf,.(Rows,Cols,Phase), function(x) data.frame(sign.inc=nrow(x[x$estim>0 & x$p.value<=pLevel,]),inc=nrow(x[x$estim>0 & x$p.value>pLevel,]),dec=nrow(x[x$estim<=0 & x$p.value>pLevel,]),sign.dec=nrow(x[x$estim<=0 & x$p.value<=pLevel,])))
sumwpf<-merge(wp,sumwpf, intersect(c('Rows','Cols','Phase'),c('Rows','Cols','Phase')))

# Statistics for detecting significant differences between Case1 and Case2 (neutral)
static.sign<-safewilTest(mppS,"Value","Case",Case1,Case2)
se<-ddply(mppS,.(Case), function(x) sqrt(var(x$Value)/length(x$Value)))

sumTable<-tabular(Rows*Cols*Phase~Heading()*identity*(estimated.difference+p.value+sign.inc+inc+dec+sign.dec), data=sumwpf)
suppress<-latex(sumTable,paste(outdirg,"\\summaryPP.tex",sep=''), digits=2)

cat(format(Sys.time(), "%H:%M:%S"),'Plotting\n')

filename<-paste(outdirg,"\\Area_Time.png",sep='')
png(filename, width, height, res=res)
p<-ggplot(mmppArea, aes(Phase, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
    scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase (%)")+
    theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
    theme(legend.position = "none")+
    facet_grid(Rows ~ Cols)
print(p)
dev.off()

filename<-paste(outdirg,"\\Neutral_measurements.png",sep='')
png(filename, width, height, res=res)
w<-ggplot(subset(mppS), aes(Case, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
    theme(axis.title=element_text(size=20),axis.text=element_text(colour='black'))+
    scale_y_continuous(name="Peak Pressure (MPa)")
print(w)
dev.off()
