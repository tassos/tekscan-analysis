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

for (j in 1:length(myFile)) {
	myData <- readMat(myFile[[j]])

	groups <- dim(myData$Rdata)[1]-nonCounted
	groupsS <- dim(myData$RdataS)[1]-nonCounted
	foot <- myData$Rdata[[groups+1]][1]
	dataTemp<-list()

	for (i in 1:groups) {
		case<-dimnames(myData$Rdata)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$Rdata[[i]][[1]])[[1]]<-myData$Rdata[[i]][[2]]
			dimnames(myData$Rdata[[i]][[1]])[[2]]<-1:ncol(myData$Rdata[[i]][[1]])
			dimnames(myData$Rdata[[i]][[1]])[[3]]<-unlist(myData$Rdata[[groups+2]])
			dataTemp[[i]]<-as.data.frame(as.table(myData$Rdata[[i]][[1]]))
			dataTemp[[i]]$Case<-as.factor(case)
			dataTemp[[i]]$Foot<-as.factor(foot)
		}
	}
	dataTemp<-ldply(dataTemp, data.frame)
	data<-rbind(data,dataTemp)
}
rm(myData)

colnames(data) <- c("Trial","Percentage","Variable","Value","Case","Foot")
data<-factorise(data)
data<-data[complete.cases(data),]

if ("PeakPressure" %in% group) {
	ppArea<-data[grep("(PeakPressure).",data$Variable),]
	ppArea$Rows<-regmatches(ppArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppArea$Variable, perl=TRUE))
	ppArea$Cols<-regmatches(ppArea$Variable,regexpr("(?<=cols: ).*",ppArea$Variable, perl=TRUE))
	ppArea$Variable<-NULL
	ppArea<-factorise(ppArea)
	
	#Cleaning up of bad or non used measurements
	pp<-data[grep("PeakPressure$",data$Variable),]
	pp<-factorise(pp)

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