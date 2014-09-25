require(ggplot2)
require(plyr)
require(grid)
require(xtable)
require(nlme)

rm(list=ls())
options("max.print"=300)

source("directory.r")
source("common.r")
source("LaTeX.r")

pLevel=0.05

load(paste(outdir,'ppArea_Static.RData',sep=''))
load(paste(outdir,'peakPressure_Static.RData',sep=''))
load(paste(outdir,'CoP_Static.RData',sep=''))
outLaTeX<-paste(outdir,"LaTeX/",sep='')
outdir<-paste(outdir,"Graphs_dPress/",sep='')

pp<-rbind(pp,CoP)

#Removing the two inactive muscles
pp<-pp[grep('(Flex Hal)|(Flex Dig)',pp$Muscle, invert=T),]
pp<-pp[pp$Case!="TA",]
pp<-factorise(pp)
pp<-pp[complete.cases(pp),]

threshold<-c(-10,-5,0,5,10)
threshold<-pi*threshold/180
labels<-c('Very (-)','Slightly (-)','Poorly (-)','Poorly (+)','Slightly (+)','Very P(+)')

#Removing the values for a muscle when it's not active
pp$Activation<-round(pp$Activation,1)
pp<-pp[pp$Activation<10 & (pp$Activation<0.9 | pp$Activation>1.1),]

pp[pp$Variable=="PeakPressure",]$Value<-pp[pp$Variable=="PeakPressure",]$Value/1E6
npp<-ddply(pp[pp$Variable=="PeakPressure",],.(Foot,Case,Trial,Muscle,Phase,Variable), function(x) data.frame(Value=x$Value/x$Value[x$Percentage == min(as.numeric(levels(factor(x$Percentage))))], Activation=x$Activation, Percentage=x$Percentage))

npp<-npp[npp$Activation!=1 & npp$Value<5,]
npp<-npp[complete.cases(npp),]

reg<-dlply(rbind(npp,pp[grep("CoP",pp$Variable),]),.(Foot,Case,Trial,Muscle,Phase,Variable), function(x) summary(lm(x$Value ~ x$Activation)))
regression<-ldply(reg,function(x) data.frame(Yintercept = x$coefficients[1], Slope=x$coefficients[2], r2=x$r.squared, p=x$coefficients[2,4]))

regSum<-ddply(regression,.(Case,Muscle,Phase,Variable), function(x) classify(x$Slope,tan(threshold),labels))

sumTable<-xtable(subset(regSum,Variable=="PeakPressure"),caption='Summary of results',digits=4)#,align="rll|l|lcc|cccc")
sumLatex<-print(sumTable,include.rownames=F, print.results=F)
write(insert.headers(sumLatex),paste(outLaTeX,"sumStaticLatex.tex",sep=''))

svg(paste(outdir,"muscleEffect.svg",sep=''))
p<-ggplot(npp, aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="Normalised Peak Pressure")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

svg(paste(outdir,"muscleCoPAP.svg",sep=''))
p<-ggplot(subset(pp,Variable=="CoP A/P"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="CoP A/P")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

svg(paste(outdir,"muscleCoPML.svg",sep=''))
p<-ggplot(subset(pp,Variable=="CoP M/L"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="CoP M/L")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

# p<-ggplot(regression[regression$Variable=="PeakPressure",], aes(Slope, fill=Case))+geom_density(alpha=0.2)#+geom_histogram(binwidth=0.05, aes(y=..density..))
# p<-p+facet_grid(Muscle~Phase)+xlim(-1,1)
# print(p)

# p<-ggplot(pp[grep("CoP M/L",pp$Variable),], aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
# p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1.5, alpha=0.4)
# p<-p+scale_y_continuous(name="Normalised Peak Pressure")
# p<-p+facet_grid(Muscle ~ Phase)
# print(p)