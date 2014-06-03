require(R.matlab)
library(reshape2)
require(plyr)

rm(list=ls())

source('directory.r')

choices<-c("PeakPressure","force","peakLocation")
group<-select.list(choices, preselect = NULL, multiple = TRUE, title = "Select which measurements to recreate", graphics = getOption("menu.graphics"))

myFile<-list()
for (i in 1:10) {
	myFile[i]  <-paste(indir,"Tekscan_Data_Foot", 36+i ,".mat",sep='')
}
data<-data.frame()

for (j in 1:length(myFile)) {
	myData <- readMat(myFile[[j]])

	groups <- dim(myData$Rdata)[1]-2
	foot <- myData$Rdata[[groups+1]][1]
	dataTemp<-list()

	for (i in 1:groups) {
		case<-dimnames(myData$Rdata)[[1]][[i]]
		
		if (case != 'empty') {
			dimnames(myData$Rdata[[i]][[1]])[[1]]<-myData$Rdata[[i]][[2]]
			dimnames(myData$Rdata[[i]][[1]])[[2]]<-1:100
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
data$Variable<-factor(data$Variable)

if ("PeakPressure" %in% group) {
	peakPressure<-data[grep("(PeakPressure)",data$Variable),]
	peakPressure<-peakPressure[grep("(PeakPressure).",peakPressure$Variable,invert=TRUE),]
	peakPressure$Variable<-factor(peakPressure$Variable)

	#Cleaning up of bad or non used measurements
	peakPressure$Variable<-factor(peakPressure$Variable)
	peakPressure$Trial<-factor(peakPressure$Trial)
	peakPressure$Foot<-factor(peakPressure$Foot)
	
	save('peakPressure',file=paste(outdir,'peakPressure.RData',sep=''))
}

if ("force" %in% group) {
	force<-data[grep("(forceTotal)",data$Variable),]
	force$Variable<-factor(force$Variable)

	#Cleaning up of bad or non used measurements
	force$Variable<-factor(force$Variable)
	force$Trial<-factor(force$Trial)
	force$Foot<-factor(force$Foot)
	
	save('force',file=paste(outdir,'force.RData',sep=''))
}

if ("peakLocation" %in% group) {
	peakL<-data[grep("(PeakLocation).",data$Variable),]
	peakL$Variable<-factor(peakL$Variable)

	#Cleaning up of bad or non used measurements
	peakL$Variable<-factor(peakL$Variable)
	peakL$Trial<-factor(peakL$Trial)
	peakL$Foot<-factor(peakL$Foot)
	
	save('peakL',file=paste(outdir,'peakL.RData',sep=''))
}