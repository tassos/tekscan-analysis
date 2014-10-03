require(ggplot2)
require(plyr)
require(grid)
require(xtable)
library(lattice)
require(lme4)

rm(list=ls())
options("max.print"=300)

source("directory.r")
source("common.r")
source("LaTeX.r")

pLevel=0.05
threshold<-c(-.1,-.05,0,.05,.1)
labels<-c('Very (-)','Slightly (-)','Poorly (-)','Poorly (+)','Slightly (+)','Very (+)')

load(paste(outdir,'ppArea_Static.RData',sep=''))
load(paste(outdir,'peakPressure_Static.RData',sep=''))
load(paste(outdir,'CoP_Static.RData',sep=''))
outdirg=paste(outdirg,'Clinical Orthopaedics and Related Research/muscleActivation/Figures/',sep='')
outLaTeX<-paste(outdirg,"LaTeX/",sep='')

pp<-rbind(pp,CoP)

#Removing the two inactive muscles
pp<-pp[grep('(Flex Hal)|(Flex Dig)',pp$Muscle, invert=T),]
pp$Case<-mapvalues(pp$Case,from=c("Tekscan","TAP","TA"), to=c("Native","TAA","TAA+TA"))
pp$Phase<-mapvalues(pp$Phase,from=c("1","2","3"), to=c("Foot-flat","Mid-stance","Toe-off"))
pp<-pp[complete.cases(pp),]
pp<-factorise(pp)

#Removing the values for a muscle when it's not active
pp$Activation<-round(pp$Activation,1)
pp<-pp[pp$Activation<10,]

pp$Activation<-factor(pp$Activation)
#Finding the default value for each muscle, phase, case, foot and trial.
pp<-ddply(pp,.(Foot,Case,Phase,Variable,Trial), function(x) data.frame(RawActiv=x$RawActiv, Muscle=x$Muscle, Activation=x$Activation, Value=x$Value, Default=unique(x[x$Percentage == min(as.character(x$Percentage)),]$Value)), .inform=T)
pp<-ddply(pp,.(Foot,Case,Muscle,Phase,Variable,Trial,Activation), function(x) data.frame(RawActiv=mean(x$RawActiv), Value=mean(x$Value), Default=mean(x$Default)))
pp$Activation<-as.numeric(as.character(pp$Activation))
pp<-pp[pp$Activation!=1,]
pp<-pp[complete.cases(pp),]
pp<-factorise(pp)

npp<-ddply(pp,.(Foot,Case,Trial,Muscle,Phase,Variable), function(x) data.frame(Value=x$Value/x$Default, Activation=x$Activation))

# reg<-dlply(rbind(npp,pp[grep("CoP",pp$Variable),1:8]),.(Foot,Case,Trial,Muscle,Phase,Variable), function(x) summary(lm(x$Value ~ x$Activation)))
# regression<-ldply(reg,function(x) data.frame(Yintercept = x$coefficients[1], Slope=x$coefficients[2], r2=x$r.squared, p=x$coefficients[2,4]))
# regSum<-ddply(regression,.(Case,Muscle,Phase,Variable), function(x) classify(x$Slope,tan(threshold),labels))

# fm0<-dlply(pp,.(Variable,Muscle,Phase,Case), function(x) lmer(Value ~ RawActiv +(1| Foot),data = x))
# fm1<-dlply(pp,.(Variable,Muscle,Phase,Case), function(x) lmer(scale(Value) ~ scale(RawActiv) +(1| Foot),data = x))
fm2<-dlply(npp,.(Variable,Muscle,Phase,Case), function(x) lmer(Value ~ Activation +(1 | Foot),data = x))

# fm0.coef<-ldply(fm0,function(x) fixef(x))
# fm1.coef<-ldply(fm1,function(x) fixef(x))
fm2.coef<-ldply(fm2,function(x) fixef(x))

sumTable<-xtable(subset(fm2.coef,Variable=="PeakPressure"),caption='Summary of results',digits=4)#,align="rll|l|lcc|cccc")
sumLatex<-print(sumTable,include.rownames=F, print.results=F)
write(sumLatex,paste(outLaTeX,"sumStaticLatex.tex",sep=''))


# svg(paste(outdirg,"muscleEffect.svg",sep=''))
p<-ggplot(subset(pp,Variable=="PeakPressure"), aes(scale(RawActiv), scale(Value), color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="Normalised Peak Pressure")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
# dev.off()

p<-ggplot(subset(npp,Variable=="PeakPressure"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="Normalised Peak Pressure")
p<-p+facet_grid(Muscle ~ Phase)
print(p)

xyplot(Value ~ RawActiv | Foot+Variable, pp, type = c("g","p","r"), index = function(x,y) coef(lm(y ~ x))[1], aspect = "xy")

svg(paste(outdirg,"muscleCoPAP.svg",sep=''))
p<-ggplot(subset(pp,Variable=="CoP A/P"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_smooth(aes(group=Case, fill=Case),method="lm", size=1, alpha=0.2, fullrange=T)
p<-p+scale_y_continuous(name="CoP A/P")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

svg(paste(outdirg,"muscleCoPML.svg",sep=''))
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