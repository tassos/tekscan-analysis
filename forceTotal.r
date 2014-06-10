require(ggplot2)
require(plyr)
require(R2HTML)
require(grid)
require(Hmisc)

rm(list=ls())
options("max.print"=300)

source("directory.r")

load(paste(outdir,'force.RData',sep=''))
outdir<-paste(outdir,"Graphs_pPressure/",sep='')

pLevel=0.05

force$Trial<-factor(force$Trial)
force<-force[grep("(foot44)|(foot45)",force$Foot, invert = T),]
force<-force[grep("(Tekscan)|(TAP)",force$Case),]
force$Foot<-factor(force$Foot)

force$Phase<-1
phases<-c()
k=''	
for (i in phases){
	force$Phase<-ifelse(as.numeric(as.character(force$Percentage)) >i,force$Phase+1,force$Phase)
}
force$Phase<-factor(force$Phase)

mf <-ddply(force,.(Foot,Case,Trial,Variable,Phase),function(x) data.frame(Mean=mean(x$Value)))

p<-ggplot(mf, aes(Foot, Mean, fill=Case))+geom_boxplot()
print(p)

# p<-ggplot(subset(force,Case=="Tekscan"), aes(Percentage, Value, color=Foot))+geom_line(aes(group=Foot))
# print(p)