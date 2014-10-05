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
pp<-subset(pp,Case!='TA')
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

# fm0<-dlply(pp,.(Variable,Muscle,Phase,Case), function(x) lmer(Value ~ RawActiv +(1| Foot),data = x))
# fm1<-dlply(pp,.(Variable,Muscle,Phase,Case), function(x) lmer(scale(Value) ~ scale(RawActiv) +(1| Foot),data = x))
fm2<-dlply(npp,.(Variable,Phase,Muscle,Case), function(x) lmer(Value ~ Activation +(1 | Foot),data = x))

# fm0.coef<-ldply(fm0,function(x) fixef(x))
# fm1.coef<-ldply(fm1,function(x) fixef(x))
fm2.coef<-ldply(fm2,function(x) c(fixef(x),coef(summary(x))['Activation',]))

# Rounding off to two digits and changing the column names for nicer printing
fm2.coef[,c(5,6,7,8,9)]<-round(fm2.coef[,c(5,6,7,8,9)],3)
dimnames(fm2.coef)[[2]][c(5,8,9)]<-c('Intercept','Std.error','t.value')
sumTable<-tabular((Phase*Case*Muscle)~Heading()*(identity)*(Estimate)*Heading()*Variable, data=fm2.coef)
suppress<-latex(sumTable,paste(outLaTeX,"peakPressure.tex",sep=''),label='tab:Summary',digits=3)

height<-700
width<-800

png(paste(outdirg,"muscleEffect.png",sep=''), height=height, width=width, res=100)
p<-ggplot(subset(npp,Variable=="PeakPressure"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_abline(aes(intercept=Intercept, slope=Estimate, color=Case), data=fm2.coef)
p<-p+scale_y_continuous(name="Normalised Peak Pressure")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

png(paste(outdirg,"muscleCoPAP.png",sep=''), height=height, width=width, res=100)
p<-ggplot(subset(npp,Variable=="CoP A/P"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_abline(aes(intercept=Intercept, slope=Estimate, color=Case), data=fm2.coef)
p<-p+scale_y_continuous(name="CoP A/P")
p<-p+facet_grid(Muscle ~ Phase)
print(p)
dev.off()

png(paste(outdirg,"muscleCoPML.png",sep=''), height=height, width=width, res=100)
p<-ggplot(subset(npp,Variable=="CoP M/L"), aes(Activation, Value, color=Case))+geom_point()#+geom_abline(aes(intercept=Yintercept, slope=Slope, color=Case),data=regression)
p<-p+geom_abline(aes(intercept=Intercept, slope=Estimate, color=Case), data=fm2.coef)
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