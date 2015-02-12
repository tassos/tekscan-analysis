require(R.matlab)
library(reshape2)
require(plyr)

rm(list=ls())
options("max.print"=300)
source("common.r")

outdir<-choose.dir(default='~',caption='Select output folder for the variable files')
myFile<-choose.files(default=outdir, caption='Select measurement files',filters=c('MATLAB files (*.mat)','*.mat'))
choices<-c("PeakPressure","force","CoP","peakLocation")
group<-select.list(choices, preselect = NULL, multiple = TRUE, title = "Select which parameters to recreate", graphics = getOption("menu.graphics"))

nonCounted = 2

data<-data.frame()
dataS<-data.frame()
ppS<-data.frame()

for (j in 1:length(myFile)) {
	myData <- readMat(myFile[[j]])

	groups <- dim(myData$Rdata)[1]-nonCounted
	groupsS <- dim(myData$RdataS)[1]-nonCounted
	specimen <- myData$Rdata[[groups+1]][1]
	dataTemp<-list()
	dataTempS<-list()

	for (i in 1:groups) {
		case<-dimnames(myData$Rdata)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$Rdata[[i]][[1]])[[1]]<-myData$Rdata[[i]][[2]]
			dimnames(myData$Rdata[[i]][[1]])[[2]]<-1:ncol(myData$Rdata[[i]][[1]])
			dimnames(myData$Rdata[[i]][[1]])[[3]]<-unlist(myData$Rdata[[groups+2]])
			dataTemp[[i]]<-as.data.frame(as.table(myData$Rdata[[i]][[1]]))
			dataTemp[[i]]$Case<-as.factor(case)
			dataTemp[[i]]$Specimen<-as.factor(specimen)
		}
	}
	dataTemp<-ldply(dataTemp, data.frame)
	data<-rbind(data,dataTemp)

	for (i in 1:groupsS) {
		case<-dimnames(myData$RdataS)[[1]][[i]]
		if (case != 'empty') {
			dimnames(myData$RdataS[[i]][[1]])[[1]]<-myData$RdataS[[i]][[2]]
			dimnames(myData$RdataS[[i]][[1]])[[2]]<-1:ncol(myData$RdataS[[i]][[1]])
			dimnames(myData$RdataS[[i]][[1]])[[3]]<-unlist(myData$RdataS[[groupsS+2]])
			dataTempS[[i]]<-as.data.frame(as.table(myData$RdataS[[i]][[1]]))
			dataTempS[[i]]$Case<-as.factor(case)
			dataTempS[[i]]$Specimen<-as.factor(specimen)
		}
	}
	dataTempS<-ldply(dataTempS, data.frame)
	dataS<-rbind(dataS,dataTempS)
}
rm(myData)

colnames(data) <- c("Trial","Percentage","Variable","Value","Case","Specimen")
colnames(dataS) <- c("Trial","Percentage","Variable","Value","Case","Specimen")
data<-factorise(data)
data<-data[complete.cases(data),]
dataS<-dataS[complete.cases(dataS),]

if ("PeakPressure" %in% group) {
	ppArea<-data[grep("(PeakPressure).",data$Variable),]
	ppArea$Rows<-regmatches(ppArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppArea$Variable, perl=TRUE))
	ppArea$Cols<-regmatches(ppArea$Variable,regexpr("(?<=cols: ).*",ppArea$Variable, perl=TRUE))
	ppArea$Variable<-NULL
	ppArea<-factorise(ppArea)
	
	#Cleaning up of bad or non used measurements
	pp<-data[grep("PeakPressure$",data$Variable),]
	pp<-factorise(pp)
	ppS<-dataS[grep("PeakPressure$",dataS$Variable),]
	ppS<-factorise(ppS)
	colnames(dataS) <- c("Trial","Percentage","Variable","Value","Case","Specimen")
    
	save('ppS',file=paste(outdir,'\\peakPressureNeutral.RData',sep=''))
	save('pp',file=paste(outdir,'\\peakPressure.RData',sep=''))
	save('ppArea',file=paste(outdir,'\\ppArea.RData',sep=''))
}

if ("force" %in% group) {
	forceArea<-data[grep("(ForceArea).",data$Variable),]
	forceArea$Rows<-regmatches(forceArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",forceArea$Variable, perl=TRUE))
	forceArea$Cols<-regmatches(forceArea$Variable,regexpr("(?<=cols: ).*",forceArea$Variable, perl=TRUE))
	forceArea$Variable<-NULL
	forceArea<-factorise(forceArea)

	force<-data[grep("(forceTotal)",data$Variable),]

	#Cleaning up of bad or non used measurements
	force<-factorise(force)
	forceS<-dataS[grep("(forceTotal)",dataS$Variable),]
	forceS<-factorise(forceS)

	save('forceS',file=paste(outdir,'\\forceNeutral.RData',sep=''))
	save('force',file=paste(outdir,'\\force.RData',sep=''))
	save('forceArea',file=paste(outdir,'\\forceArea.RData',sep=''))
}

if ("peakLocation" %in% group) {
	peakL<-data[grep("(PeakLocation).",data$Variable),]
	peakL<-factorise(peakL)
	
	save('peakL',file=paste(outdir,'\\peakL.RData',sep=''))
}

if ("CoP" %in% group) {
	CoP<-data[grep("(CoP).",data$Variable),]
	CoP<-factorise(CoP)
	
	save('CoP',file=paste(outdir,'\\CoP.RData',sep=''))
}