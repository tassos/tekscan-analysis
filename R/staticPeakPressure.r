require(ggplot2)
require(plyr)
require(grid)
require(tables)
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
load(paste(outdir,'peakL_Static.Rdata',sep=''))
outdirg=paste(outdirg,'Clinical Orthopaedics and Related Research/muscleActivation/Figures/',sep='')

pp<-rbind(pp,CoP,peakL)

#Removing the two inactive muscles
pp<-pp[grep('(Flex Hal)|(Flex Dig)',pp$Muscle, invert=T),]
pp$Case<-mapvalues(pp$Case,from=c("Tekscan","TAP","TA"), to=c("Native","TAA","TAA+TA"))
pp$Phase<-mapvalues(pp$Phase,from=c("1","2","3"), to=c("Foot-flat","Mid-stance","Toe-off"))
pp<-subset(pp,Case!='TAA+TA')
pp<-pp[complete.cases(pp),]
pp<-factorise(pp)

#Finding the default value for each muscle, phase, case, foot and trial.
pp$Activation<-factor(pp$Activation)
pp<-ddply(pp,.(Foot,Case,Phase,Variable,Trial), function(x) data.frame(RawActiv=x$RawActiv, Muscle=x$Muscle, Activation=x$Activation, Value=x$Value, Default=unique(x[x$Percentage == min(as.character(x$Percentage)),]$Value)), .inform=T)
pp<-ddply(pp,.(Foot,Case,Muscle,Phase,Variable,Trial,Activation), function(x) data.frame(RawActiv=mean(x$RawActiv), Value=mean(x$Value), Default=mean(x$Default)))
pp$Activation<-as.numeric(as.character(pp$Activation))
pp$Activation<-round(pp$Activation,1)
pp<-pp[pp$Activation!=1 & pp$Activation<10,]

# Normalising the measured variable
npp<-ddply(subset(pp,Variable=="PeakPressure"),.(Foot,Case,Trial,Muscle,Phase,Variable), function(x) data.frame(Value=x$Value/x$Default, Activation=x$Activation))

# Constructing linear mixed-effect models for each phase and muscle and case for the peak pressure as a response. The Activation is the fixed effect variable while the Foot is the random one.
fm0<-factorise(fit_model(npp,"PeakPressure",0))
fm1<-factorise(fit_model(pp,"CoP",1))
fm2<-factorise(fit_model(pp,"PeakLocation",1))

# Merging the two location models
names(fm1)[1]<-'Direction'
fm1$Variable<-factor("Center of Pressure")
names(fm2)[1]<-'Direction'
fm2$Variable<-factor("Peak Location")
fm12<-rbind(fm1,fm2)

# Rounding off to two digits and changing the column names for nicer printing
sumTablePP<-tabular(Phase*Case*Muscle~Heading()*identity*Activation*Heading()*Variable, data=fm0)
suppress<-latex(sumTablePP,paste(outdirg,"LaTeX/peakPressure.tex",sep=''))

sumTableCoP<-tabular(Phase*Case*Muscle~Variable*Direction*Heading()*identity*(Intercept+Activation), data=fm12)
suppress<-latex(sumTableCoP,paste(outdirg,"LaTeX/Location.tex",sep=''))

#Converting to a wide format, so that I can use the different variables for the aesthetics of the plot
cop<-reshape(pp, idvar=c("Foot","Case","Trial","Phase","Muscle","Activation"), timevar="Variable", drop=c('Default','RawActiv'), direction="wide")
dimnames(cop)[[2]][c(7:11)]<-c('PP','CoPAP','CoPML','PLAP','PLML')

# Gathering the model estimates for drawing the predictor arrows
fm1<-reshape(fm1, idvar=c("Phase","Muscle","Case"), timevar="Variable", direction="wide")
fm2<-reshape(fm2., idvar=c("Phase","Muscle","Case"), timevar="Variable", direction="wide")

# Defining height and width for the output figures and plotting
height<-700
width<-800
res<-100

png(paste(outdirg,"muscleEffect.png",sep=''), height, width, res=res)
p<-ggplot(npp, aes(Activation, Value, color=Case))+geom_point()+
	geom_abline(aes(intercept=Intercept, slope=Activation, color=Case), data=fm0)+
	scale_y_continuous(name="Normalised Peak Pressure")+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	facet_grid(Muscle ~ Phase)
print(p)
dev.off()

png(paste(outdirg,"muscleCoP.png",sep=''), height, width, res=100)
p<-ggplot(cop, aes(CoPML, CoPAP, color=Case))+geom_point(aes(alpha=PP))+
	geom_segment(aes(x=Intercept.ML, y=Intercept.AP, xend=Intercept.ML+Activation.ML*10,
	yend=Intercept.AP+Activation.AP*10), color=c("red",'blue'), size=1, data=fm1, arrow = arrow(length=unit(0.3,'cm')))+
	scale_x_continuous(name="CoP medial-lateral",limits=c(-16,16))+scale_y_continuous(name="CoP anterior-posterior", limits=c(-23,23))+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	facet_grid(Muscle ~ Phase)
print(p)
dev.off()