require(ggplot2)
require(plyr)
require(grid)
require(tables)
require(nlme)

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
load(paste(outdir,'peakL_Static.RData',sep=''))
outdirg=paste(outdirg,'Clinical Orthopaedics and Related Research/muscleActivation/',sep='')

pp<-rbind(pp,CoP,peakL)
cat(format(Sys.time(), "%H:%M:%S"),' Manipulating input data\n')

# Removing the two inactive muscles
pp<-pp[grep('(Flex Hal)|(Flex Dig)',pp$Muscle, invert=T),]
pp$Case<-mapvalues(pp$Case,from=c("Tekscan","TAP","TA"), to=c("Native","TAA","TAA+TA"))
pp$Phase<-mapvalues(pp$Phase,from=c("1","2","3"), to=c("Foot-flat","Mid-stance","Toe-off"))
# Inverting so that Anterior is positive and posterior negative
pp[grep('A/P',pp$Variable),]$Value<--pp[grep('A/P',pp$Variable),]$Value
pp<-subset(pp,Case!='TAA+TA')
pp<-subset(pp,Foot!='foot45')
pp<-pp[complete.cases(pp),]
pp$Activation<-round(pp$Activation,1)
pp<-factorise(pp)

# Finding the default value for each muscle, phase, case, foot and trial.
pp$Activation<-factor(pp$Activation)
pp<-ddply(pp,.(Foot,Case,Phase,Variable,Trial), function(x) data.frame(RawActiv=x$RawActiv, Muscle=x$Muscle, Activation=x$Activation, Value=x$Value, Default=unique(x[x$Percentage == min(as.character(x$Percentage)),]$Value)), .inform=T)
pp<-pp[as.numeric(as.character(pp$Activation))!=1 & as.numeric(as.character(pp$Activation))<10,]

cat(format(Sys.time(), "%H:%M:%S"),' Normalising peak pressure values\n')
# Normalising the measured variable
npp<-ddply(subset(pp,Variable=="PeakPressure"),.(Foot,Case,Muscle,Phase,Variable,Trial), function(x) data.frame(Value=x$Value/x$Default, Activation=x$Activation))
npp<-ddply(npp,.(Foot,Case,Muscle,Phase,Variable,Activation), function(x) data.frame(Value=mean(x$Value)))
npp$Activation<-as.numeric(as.character(npp$Activation))
npp<-npp[complete.cases(npp),]

pp<-ddply(pp,.(Foot,Case,Muscle,Phase,Variable,Activation), function(x) data.frame(RawActiv=mean(x$RawActiv), Value=mean(x$Value), Default=mean(x$Default)))
pp$Activation<-as.numeric(as.character(pp$Activation))

cat(format(Sys.time(), "%H:%M:%S"),' Calculating mixed-effects models\n')
# Constructing linear mixed-effect models for each phase and muscle and case for the peak pressure as a response. The Activation is the fixed effect variable while the Foot is the random one.
fm0<-factorise(fit_model(npp,"PeakPressure",0,pLevel))
fm1<-factorise(fit_model(pp,"CoP",1,pLevel))
fm2<-factorise(fit_model(pp,"PeakLocation",1,pLevel))

# Converting to a wide format, so that I can use the different variables for the aesthetics of the plot
cop<-reshape(pp, idvar=c("Foot","Case","Muscle","Phase","Activation"), timevar="Variable", varying=list(c('PP','CoPAP','CoPML','PLAP','PLML')), drop=c('Default','RawActiv'), direction="wide")
cop<-cop[complete.cases(cop),]

# Gathering the model estimates for drawing the predictor arrows
fm1r<-reshape(fm1, idvar=c("Phase","Muscle","Case","maxActiv"), timevar="Variable", direction="wide")
fm2r<-reshape(fm2, idvar=c("Phase","Muscle","Case","maxActiv"), timevar="Variable", direction="wide")
fm1r$p.star<-ifelse((fm1r$p.star.AP=="*"&fm1r$p.star.ML=="*"),"*"," ")
fm2r$p.star<-ifelse((fm2r$p.star.AP=="*"&fm2r$p.star.ML=="*"),"*"," ")

cat(format(Sys.time(), "%H:%M:%S"),' Plotting figures\n')

# Defining height and width for the output figures and plotting
height<-1400
width<-1600
res<-150

png(paste(outdirg,"Figures/muscleEffect.png",sep=''), height, width, res=res)
p<-ggplot(npp, aes(Activation, Value, color=Case))+geom_point(alpha=0.8)+
	geom_text(data=fm0, aes(x=15, y=3*as.numeric(Case), label=p.star), color=c("firebrick","darkblue"), size=8)+
	geom_segment(aes(x=0, y=Intercept, xend=maxActiv+1,
	yend=Intercept+Activation*(maxActiv+1)), color=c("red",'darkblue'), size=1, data=fm0)+
	scale_y_continuous(name="Normalised peak pressure")+scale_x_continuous(name="Normalised muscle force")+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	theme(legend.title=element_text(size=20), legend.text=element_text(size=12))+
	facet_grid(Muscle ~ Phase)
print(p)
dev.off()

png(paste(outdirg,"Figures/muscleCoP.png",sep=''), height, width, res=res)
q<-ggplot(cop, aes(CoPML, CoPAP, color=Case))+geom_point(aes(alpha=PP))+
	scale_alpha_continuous(guide = guide_legend(title = "Peak Pressure"))+
	geom_text(data=fm1r, aes(x=15, y=4*as.numeric(Case), label=p.star), color=c("firebrick","darkblue"), size=8)+
	geom_segment(aes(x=Intercept.ML, y=Intercept.AP, xend=Intercept.ML+Activation.ML*10,
	yend=Intercept.AP+Activation.AP*10), color=c("firebrick",'darkblue'), size=1, data=fm1r, arrow = arrow(length=unit(0.3,'cm')))+
	scale_x_continuous(name="CoP medial(-)/lateral(+) (mm)",limits=c(-16,16))+scale_y_continuous(name="CoP posterior(-)/anterior(+) (mm)", limits=c(-23,23))+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	theme(legend.title=element_text(size=20), legend.text=element_text(size=12))+
	facet_grid(Muscle ~ Phase)
print(q)
dev.off()

png(paste(outdirg,"Figures/musclePP.png",sep=''), height, width, res=res)
r<-ggplot(cop, aes(PLML, PLAP, color=Case))+geom_point(aes(alpha=PP))+
	scale_alpha_continuous(guide = guide_legend(title = "Peak Pressure"))+
	geom_text(data=fm2r, aes(x=15, y=4*as.numeric(Case), label=p.star), color=c("firebrick","darkblue"), size=8)+
	geom_segment(aes(x=Intercept.ML, y=Intercept.AP, xend=Intercept.ML+Activation.ML*10,
	yend=Intercept.AP+Activation.AP*10), color=c("red",'darkblue'), size=1, data=fm2r, arrow = arrow(length=unit(0.3,'cm')))+
	scale_x_continuous(name="Peak Pressure medial(-)/lateral(+) (mm)",limits=c(-16,16))+scale_y_continuous(name="Peak Pressure posterior(-)/anterior(+) (mm)", limits=c(-23,23))+
	theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
	theme(legend.title=element_text(size=20), legend.text=element_text(size=12))+
	facet_grid(Muscle ~ Phase)
print(r)
dev.off()

cat(format(Sys.time(), "%H:%M:%S"),' Exporting to LaTeX\n')

# Merging the two location models
names(fm1)[1]<-'Direction'
fm1$Variable<-factor("Center of Pressure")
names(fm2)[1]<-'Direction'
fm2$Variable<-factor("Peak Location")
fm12<-rbind(fm1,fm2)

# Rounding off to two digits and changing the column names for nicer printing
sumTablePP<-tabular(Phase*Case*Muscle~Heading()*identity*Variable*(Intercept+Activation+p.value), data=fm0)
suppress<-latex(sumTablePP,paste(outdirg,"LaTeX/peakPressure.tex",sep=''))

sumTableCoP<-tabular(Phase*Case*Muscle~Heading()*Variable*Heading()*Direction*Heading()*identity*(Intercept+Activation+p.value), data=fm1)
suppress<-latex(sumTableCoP,paste(outdirg,"LaTeX/Location.tex",sep=''), options=list(titlerule = '\\cline' ))
