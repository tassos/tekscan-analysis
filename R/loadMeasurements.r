require(R.matlab)
library(reshape2)
require(plyr)

rm(list=ls())
options("max.print"=300)

source('directory.r')
source("common.r")

choices<-c("PeakPressure","force","CoP","peakLocation","PeakPressure Talus","StaticProtocol")
group<-select.list(choices, preselect = NULL, multiple = TRUE, title = "Select which measurements to recreate", graphics = getOption("menu.graphics"))

if ("StaticProtocol" %in% group) {
	type = "_Static"
} else {
	type = ""
}
nonCounted = 3

myFile<-list()
for (i in 1:10) {
	myFile[i]  <-paste(indir,"Tekscan_Data",type,"_foot", 36+i ,".mat",sep='')
}
data<-data.frame()
fLevels<-data.frame()
ppTArea<-data.frame()
ppS<-data.frame()

for (j in 1:length(myFile)) {
	myData <- readMat(myFile[[j]])

	groups <- dim(myData$Rdata)[1]-nonCounted
	groupsT <- dim(myData$RdataT)[1]-nonCounted
	groupsS <- dim(myData$RdataS)[1]-nonCounted
	foot <- myData$Rdata[[groups+1]][1]
	dataTemp<-list()
	dataTempT<-list()
	dataTempS<-list()
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
				dimnames(myData$Rdata[[i]][[3]])[[2]]<-1:ncol(myData$Rdata[[i]][[3]])
				dimnames(myData$Rdata[[i]][[3]])[[3]]<-myData$Rdata[[groups+nonCounted]][1:6]
				dimnames(myData$Rdata[[i]][[4]])[[1]]<-myData$Rdata[[i]][[2]]
				dimnames(myData$Rdata[[i]][[4]])[[2]]<-1:ncol(myData$Rdata[[i]][[3]])
				fLevelsTemp[[i]] <- as.data.frame(as.table(myData$Rdata[[i]][[3]]))
				fLevelsTemp[[i]]$Phase <- as.factor(as.data.frame(as.table(myData$Rdata[[i]][[4]]))$Freq)
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
	
	for (i in 1:groupsS) {
		case<-dimnames(myData$RdataS)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$RdataS[[i]][[1]])[[1]]<-myData$RdataS[[i]][[2]]
			dimnames(myData$RdataS[[i]][[1]])[[2]]<-1:ncol(myData$RdataS[[i]][[1]])
			dimnames(myData$RdataS[[i]][[1]])[[3]]<-unlist(myData$RdataS[[groupsS+2]])
			dataTempS[[i]]<-as.data.frame(as.table(myData$RdataS[[i]][[1]]))
			dataTempS[[i]]$Case<-as.factor(case)
			dataTempS[[i]]$Foot<-as.factor(foot)
		}
	}
	dataTempT<-ldply(dataTempT, data.frame)
	ppTArea<-rbind(ppTArea,dataTempT)
	ppSTemp<-ldply(dataTempS, data.frame)
	ppS<-rbind(ppS,ppSTemp)
}
rm(myData)

colnames(data) <- c("Trial","Percentage","Variable","Value","Case","Foot")
colnames(ppTArea) <- c("Trial","Percentage","Variable","Value","Case","Foot")
colnames(ppS) <- c("Trial","Percentage","Variable","Value","Case","Foot")
data<-factorise(data)
ppTArea<-factorise(ppTArea)
if (type == "_Static") {
	fLevels<-fLevels[complete.cases(fLevels),]
	colnames(fLevels) <- c("Trial","Percentage","Muscle","Activation","Phase","Case","Foot")
	data<-merge(data, fLevels, by=c("Trial","Percentage","Case","Foot"))
}
data<-data[complete.cases(data),]
ppTArea<-ppTArea[complete.cases(ppTArea),]

if ("PeakPressure" %in% group) {
	ppArea<-data[grep("(PeakPressure).",data$Variable),]
	ppArea$Rows<-regmatches(ppArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppArea$Variable, perl=TRUE))
	ppArea$Cols<-regmatches(ppArea$Variable,regexpr("(?<=cols: ).*",ppArea$Variable, perl=TRUE))
	ppArea$Variable<-NULL
	ppArea<-factorise(ppArea)
	
	#Cleaning up of bad or non used measurements
	pp<-data[grep("(PeakPressure)",data$Variable),]
	pp<-pp[grep("(PeakPressure).",pp$Variable, invert=T),]
	pp$Variable<-NULL
	pp<-factorise(pp)
	
	ppS<-ppS[grep("(PeakPressure)",ppS$Variable),]
	ppS<-ppS[grep("(PeakPressure).",ppS$Variable, invert=T),]
	
	save('pp',file=paste(outdir,'peakPressure',type,'.RData',sep=''))
	save('ppS',file=paste(outdir,'peakPressureNeutral',type,'.RData',sep=''))
	save('ppArea',file=paste(outdir,'ppArea',type,'.RData',sep=''))
}

if ("force" %in% group) {
	forceArea<-data[grep("(ForceArea).",data$Variable),]
	forceArea$Rows<-regmatches(forceArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",forceArea$Variable, perl=TRUE))
	forceArea$Cols<-regmatches(forceArea$Variable,regexpr("(?<=cols: ).*",forceArea$Variable, perl=TRUE))
	forceArea$Variable<-NULL
	forceArea<-factorise(forceArea)

	force<-data[grep("(forceTotal)",data$Variable),]
	forceS<-data[grep("(forceTotal)",ppS$Variable),]

	#Cleaning up of bad or non used measurements
	force<-factorise(force)
	forceS<-factorise(forceS)
	
	save('force',file=paste(outdir,'force',type,'.RData',sep=''))
	save('forceS',file=paste(outdir,'forceNeutral',type,'.RData',sep=''))
	save('forceArea',file=paste(outdir,'forceArea',type,'.RData',sep=''))
}

if ("peakLocation" %in% group) {
	peakL<-data[grep("(PeakLocation).",data$Variable),]
	peakL<-factorise(peakL)
	
	save('peakL',file=paste(outdir,'peakL',type,'.RData',sep=''))
}

if ("CoP" %in% group) {
	CoP<-data[grep("(CoP).",data$Variable),]
	CoP<-factorise(CoP)
	
	save('CoP',file=paste(outdir,'CoP',type,'.RData',sep=''))
}


if ("PeakPressure Talus" %in% group & type != "_Static") {
	ppTArea$Rows<-regmatches(ppTArea$Variable,regexpr("(?<=rows: ).*(?=cols:)",ppTArea$Variable, perl=TRUE))
	ppTArea$Cols<-regmatches(ppTArea$Variable,regexpr("(?<=cols: ).*",ppTArea$Variable, perl=TRUE))
	ppTArea$Variable<-NULL
	ppTArea<-factorise(ppTArea)
	
	save('ppTArea',file=paste(outdir,'ppTArea.RData',sep=''))
}
