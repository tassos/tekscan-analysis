require(ggplot2)
require(plyr)
require(grid)
require(tables)
require(pwr)

rm(list=ls())
options("max.print"=300)
pLevel=0.05
phases<-c(0,20,40,60,80,100)

print<-F

source("directory.r")
source("common.r")
source('LaTeX.r')

cat(format(Sys.time(), "%H:%M:%S"),'Loading data\n')

load(paste(outdir,'ppArea.RData',sep=''))
load(paste(outdir,'ppTArea.RData',sep=''))
load(paste(outdir,'peakPressureNeutral.RData',sep=''))
outdirg=paste(outdirg,'Clinical Orthopaedics and Related Research/peakPressure/',sep='')

# Combining the data frames of the Tibia and Talus pressures and cleaning the bad data points
ppArea<-rbind(ppTArea,ppArea)
ppArea<-ppArea[complete.cases(ppArea),]

cat(format(Sys.time(), "%H:%M:%S"),'Manipulating input data\n')

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

cat(format(Sys.time(), "%H:%M:%S"),'Calculating peak pressure measures\n')

# Calculating the maximum peak pressure for each Foot, Case, Trial, Area and Phase
mppArea<-ddply(ppArea,.(Foot,Case,Trial,Rows,Cols,Phase),function(x) data.frame(Value=max(x$Value/1E6)))
mmppArea<-ddply(mppArea,.(Foot,Case,Rows,Cols,Phase),function(x) data.frame(Value=mean(x$Value)))
medppArea<-ddply(mmppArea,.(Case,Rows,Cols,Phase), function(x) data.frame(Value=median(x$Value)))

# Calculating the location of the maximum and minumum median peak pressure
medmax<-ddply(medppArea,.(Case,Phase), function(x) x[x$Value==max(x$Value),])
medmin<-ddply(medppArea,.(Case,Phase), function(x) x[x$Value==min(x$Value),])

# Calculating the maximum peak pressure for each Foot, Case, Trial for the neutral position measurements
mppS <-ddply(subset(ppS,Case!='TA'),.(Foot,Case,Trial), function(x) data.frame(Value=max(x$Value/1E6)))
mppS <-ddply(mppS,.(Foot,Case), function(x) data.frame(Value=mean(x$Value)))
mppS$Case<-mapvalues(mppS$Case,from=c("Tekscan","TAP"), to=c("Native Tibia","TAA Tibia"))

cat(format(Sys.time(), "%H:%M:%S"),'Calculating statistics\n')

# Statistics for detecting significant differences between Native and TAP (dynamic)
wp<-ddply(mmppArea,.(Rows,Cols,Phase), function(x) data.frame(estimated.difference=round(safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$estimate,3),p.value=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$p.value))
wp$p.value<-ifelse(wp$p.value <=pLevel,paste(round(wp$p.value,3),"(*)"),round(wp$p.value,3))

wpf<-ddply(mppArea,.(Foot,Rows,Cols,Phase), function(x) data.frame(estim=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$estimate,p.value=safewilTest(x,"Value","Case","TAA Tibia","Native Tibia")$p.value))
wpf$p.star<-ifelse(wpf$p.value <=pLevel,"(*)"," ")
sumwpf<-ddply(wpf,.(Rows,Cols,Phase), function(x) data.frame(sign.inc=nrow(x[x$estim>0 & x$p.value<=pLevel,]),inc=nrow(x[x$estim>0 & x$p.value>pLevel,]),dec=nrow(x[x$estim<=0 & x$p.value>pLevel,]),sign.dec=nrow(x[x$estim<=0 & x$p.value<=pLevel,])))
sumwpf<-merge(wp,sumwpf, intersect(c('Rows','Cols','Phase'),c('Rows','Cols','Phase')))

# Statistics for detecting significant differences between Native and TAP (neutral)
static.sign<-safewilTest(mppS,"Value","Case","TAA Tibia","Native Tibia")
se<-ddply(mppS,.(Case), function(x) sqrt(var(x$Value)/length(x$Value)))

if (print){
	sumTable<-tabular(Rows*Cols*Phase~Heading()*identity*(estimated.difference+p.value+sign.inc+inc+dec+sign.dec), data=sumwpf)
	suppress<-latex(sumTable,paste(outdirg,"LaTeX/summaryPP.tex",sep=''), digits=2)

	cat(format(Sys.time(), "%H:%M:%S"),'Plotting\n')

	filename<-paste(outdirg,"Figures/Area_Time_Talus",sep='')
	png(paste(filename,".png",sep=''), height=height, width=width, res=res)
	p<-ggplot(subset(mmppArea, Case=="Native Talus"), aes(Phase, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
		scale_fill_manual(values=c("green4"))+
		scale_y_continuous(name="Peak Pressure (MPa)")+scale_x_discrete(name="Stance phase (%)")+
		theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
		theme(legend.position = "none")+
		facet_grid(Rows ~ Cols)
	print(p)
	dev.off()

	filename<-paste(outdirg,"Figures/Area_Time_Tibia",sep='')
	png(paste(filename,".png",sep=''), height=height, width=width, res=res)
	q<-ggplot(subset(mmppArea, Case!="Native Talus"), aes(Phase, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
		scale_y_continuous(name="Peak Pressure (MPa)", limits=c(0,10))+scale_x_discrete(name="Stance phase (%)")+
		theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
		facet_grid(Rows ~ Cols)
	print(q)
	dev.off()

	for (bone in c('Talus','Tibia')) {
		save_png(height,width,bone,paste(outdirg,'Figures/Temporal-Time_',sep=''))
	}

	filename<-paste(outdirg,"Figures/Neutral_measurements",sep='')
	png(paste(filename,".png",sep=''), res=res, height=400, width=500)
	w<-ggplot(subset(mppS), aes(Case, Value, fill=Case))+geom_boxplot(outlier.shape=NA)+
		theme(axis.title=element_text(size=20),axis.text=element_text(colour='black'))+
		scale_y_continuous(name="Peak Pressure (MPa)")
	print(w)
	dev.off()
}