require(R.matlab)
library(reshape2)
require(plyr)

rm(list=ls())
options("max.print"=300)

source('directory.r')

choices<-c("PeakPressure","force","peakLocation","PeakPressure Talus","StaticProtocol")
group<-select.list(choices, preselect = NULL, multiple = TRUE, title = "Select which measurements to recreate", graphics = getOption("menu.graphics"))

if ("StaticProtocol" %in% group) {
	type = "_Static"
	nonCounted = 3
} else {
	type = ""
	nonCounted = 2
}

myFile<-list()
for (i in 1:10) {
	myFile[i]  <-paste(indir,"Tekscan_Data",type,"_foot", 36+i ,".mat",sep='')
}
data<-data.frame()
fLevels<-data.frame()
ppTArea<-data.frame()

for (j in 1:length(myFile)) {
	myData <- readMat(myFile[[j]])

	groups <- dim(myData$Rdata)[1]-nonCounted
	groupsT <- dim(myData$RdataT)[1]-nonCounted
	foot <- myData$Rdata[[groups+1]][1]
	dataTemp<-list()
	dataTempT<-list()
	fLevelsTemp<-list()

	for (i in 1:groups) {
		case<-dimnames(myData$Rdata)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$Rdata[[i]][[1]])[[1]]<-myData$Rdata[[i]][[2]]
			dimnames(myData$Rdata[[i]][[1]])[[2]]<-1:ncol(myData$Rdata[[i]][[1]])
			dimnames(myData$Rdata[[i]][[1]])[[3]]<-unlist(myData$Rdata[[groups+2]])
			dataTemp[[i]]<-as.data.frame(as.table(myData$Rdata[[i]][[1]]))
			dataTemp[[i]]$Case<-as.factor(case)
			dataTemp[[i]]$Foot<-as.factor(foot)
			if (type == '_Static') {
				dimnames(myData$Rdata[[i]][[3]])[[1]]<-myData$Rdata[[i]][[2]]
				dimnames(myData$Rdata[[i]][[3]])[[2]]<-1:ncol(myData$Rdata[[i]][[1]])
				dimnames(myData$Rdata[[i]][[3]])[[3]]<-myData$Rdata[[groups+nonCounted]]
				fLevelsTemp[[i]] <- as.data.frame(as.table(myData$Rdata[[i]][[3]]))
				fLevelsTemp[[i]]$Case<-as.factor(case)
				fLevelsTemp[[i]]$Foot<-as.factor(foot)
			}
		}
	}
	if (type == '_Static') {
		fLevelsTemp<-ldply(fLevelsTemp,data.frame)
		fLevels<-rbind(fLevels,fLevelsTemp)
	}
	dataTemp<-ldply(dataTemp, data.frame)
	data<-rbind(data,dataTemp)
	
	for (i in 1:groupsT) {
		case<-dimnames(myData$RdataT)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$RdataT[[i]][[1]])[[1]]<-myData$RdataT[[i]][[2]]
			dimnames(myData$RdataT[[i]][[1]])[[2]]<-1:ncol(myData$RdataT[[i]][[1]])
			dimnames(myData$RdataT[[i]][[1]])[[3]]<-unlist(myData$RdataT[[groupsT+2]])
			dataTempT[[i]]<-as.data.frame(as.table(myData$RdataT[[i]][[1]]))
			dataTempT[[i]]$Case<-as.factor(case)
			dataTempT[[i]]$Foot<-as.factor(foot)
		}
	}
	dataTempT<-ldply(dataTempT, data.frame)
	ppTArea<-rbind(ppTArea,dataTempT)
}
rm(myData)

colnames(fLevels) <- c("Trial","Percentage","Muscle","Activation","Case","Foot")
colnames(data) <- c("Trial","Percentage","Variable","Value","Case","Foot")
colnames(ppTArea) <- c("Trial","Percentage","Variable","Value","Case","Foot")
data$Variable<-factor(data$Variable)
ppTArea$Variable<-factor(ppTArea$Variable)
if (type == "_Static") {
	data<-merge(data, fLevels, by=c("Trial","Percentage","Case","Foot"))
}

if ("PeakPressure" %in% group) {
	ppArea<-data[grep("(PeakPressure).",data$Variable),]
	ppArea$Rows<-regmatches(ppArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppArea$Variable, perl=TRUE))
	ppArea$Cols<-regmatches(ppArea$Variable,regexpr("(?<=cols: ).*",ppArea$Variable, perl=TRUE))
	ppArea$Rows<-factor(ppArea$Rows)
	ppArea$Cols<-factor(ppArea$Cols)
	ppArea$Variable<-factor(ppArea$Variable)
	
	#Cleaning up of bad or non used measurements
	pp<-data[grep("(PeakPressure)",data$Variable),]
	pp<-pp[grep("(PeakPressure).",pp$Variable, invert=T),]
	pp$Variable<-factor(pp$Variable)
	pp$Trial<-factor(pp$Trial)
	pp$Foot<-factor(pp$Foot)
	
	save('pp',file=paste(outdir,'peakPressure',type,'.RData',sep=''))
	save('ppArea',file=paste(outdir,'ppArea',type,'.RData',sep=''))
}

if ("force" %in% group) {
	force<-data[grep("(forceTotal)",data$Variable),]
	force$Variable<-factor(force$Variable)

	#Cleaning up of bad or non used measurements
	force$Variable<-factor(force$Variable)
	force$Trial<-factor(force$Trial)
	force$Foot<-factor(force$Foot)
	
	save('force',file=paste(outdir,'force',type,'.RData',sep=''))
}

if ("peakLocation" %in% group) {
	peakL<-data[grep("(PeakLocation).",data$Variable),]
	peakL$Variable<-factor(peakL$Variable)

	#Cleaning up of bad or non used measurements
	peakL$Variable<-factor(peakL$Variable)
	peakL$Trial<-factor(peakL$Trial)
	peakL$Foot<-factor(peakL$Foot)
	
	save('peakL',file=paste(outdir,'peakL',type,'.RData',sep=''))
}

if ("PeakPressure Talus" %in% group) {
	ppTArea$Rows<-regmatches(ppTArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppTArea$Variable, perl=TRUE))
	ppTArea$Cols<-regmatches(ppTArea$Variable,regexpr("(?<=cols: ).*",ppTArea$Variable, perl=TRUE))
	ppTArea$Rows<-factor(ppTArea$Rows)
	ppTArea$Cols<-factor(ppTArea$Cols)
	
	#Cleaning up of bad or non used measurements
	ppTArea$Variable<-factor(ppTArea$Variable)
	ppTArea$Trial<-factor(ppTArea$Trial)
	ppTArea$Foot<-factor(ppTArea$Foot)
	
	save('ppTArea',file=paste(outdir,'ppTArea.RData',sep=''))
}
