require(ggplot2)
require(plyr)
require(grid)
require(tables)
require(nlme)

rm(list=ls())
options("max.print"=300)

print<-F

source("directory.r")
source("common.r")
source("LaTeX.r")

pLevel=0.05

load(paste(outdir,'ppArea_Static.RData',sep=''))
load(paste(outdir,'peakPressure_Static.RData',sep=''))
load(paste(outdir,'CoP_Static.RData',sep=''))
load(paste(outdir,'peakL_Static.RData',sep=''))
outdirg=paste(outdirg,'Clinical Orthopaedics and Related Research/muscleActivation/',sep='')

pp<-rbind(pp,CoP,peakL)
dimnames(pp)[[2]][8]<-'Actuation'
cat(format(Sys.time(), "%H:%M:%S"),' Manipulating input data\n')

# Removing the two inactive muscles
pp<-pp[grep('(Flex Hal)|(Flex Dig)',pp$Muscle, invert=T),]
pp$Case<-mapvalues(pp$Case,from=c("Tekscan","TAP","TA"), to=c("Native","TAA","TAA+TA"))
pp$Phase<-mapvalues(pp$Phase,from=c("1","2","3"), to=c("Foot-flat","Mid-stance","Toe-off"))
pp$Muscle<-mapvalues(pp$Muscle,from=c("Gastroc"), to=c("Tr surae"))
# Inverting so that Anterior is positive and posterior negative
pp[grep('A/P',pp$Variable),]$Value<--pp[grep('A/P',pp$Variable),]$Value
pp<-subset(pp,Case!='TAA+TA')
pp<-pp[pp$Foot!='foot46',]
pp$Actuation<-round(pp$Actuation,1)
pp<-factorise(pp)
pp<-pp[complete.cases(pp),]

pp$Foot<-mapvalues(pp$Foot,from=c("foot37","foot38","foot39","foot40","foot41","foot42","foot43","foot44","foot45"),
	to=c("Specimen1","Specimen2","Specimen3","Specimen4","Specimen5","Specimen6","Specimen7","Specimen8","Specimen9"))

# Creating a summary table with the forces that were applied to the specimens
forces<-ddply(subset(pp,Variable=="PeakPressure"),.(Foot,Phase,Muscle), function(x) data.frame(Max=max(x$RawActiv),Initial=mean(x[x$Percentage == min(as.numeric(as.character(x$Percentage))),]$RawActiv)))

# Finding the default value for each muscle, phase, case, foot and trial.
pp$Actuation<-factor(pp$Actuation)
pp<-ddply(pp,.(Foot,Case,Phase,Variable,Trial), function(x) data.frame(RawActiv=x$RawActiv, Muscle=x$Muscle, Actuation=x$Actuation, Value=x$Value, Default=mean(x[x$Percentage == min(as.numeric(as.character(x$Percentage))),]$Value),DefaultAct=mean(x[x$Percentage == min(as.numeric(as.character(x$Percentage))),]$RawActiv)), .inform=T)
pp<-pp[as.numeric(as.character(pp$Actuation))!=1 & as.numeric(as.character(pp$Actuation))<10,]
pp<-pp[complete.cases(pp),]

cat(format(Sys.time(), "%H:%M:%S"),' Normalising peak pressure values\n')
# Normalising the measured variable
npp<-ddply(subset(pp,Variable=="PeakPressure"),.(Foot,Case,Muscle,Phase,Variable,Trial), function(x) data.frame(Value=x$Value/x$Default, Actuation=x$Actuation))
npp<-ddply(npp,.(Foot,Case,Muscle,Phase,Variable,Actuation), function(x) data.frame(Value=mean(x$Value)))
npp$Actuation<-as.numeric(as.character(npp$Actuation))
npp<-factorise(npp)
npp<-npp[complete.cases(npp),]

pp<-ddply(pp,.(Foot,Case,Muscle,Phase,Variable,Actuation), function(x) data.frame(RawActiv=mean(x$RawActiv), Value=mean(x$Value), Default=mean(x$Default)))
pp$Actuation<-as.numeric(as.character(pp$Actuation))

cat(format(Sys.time(), "%H:%M:%S"),' Calculating mixed-effects models\n')
# Constructing linear mixed-effect models for each phase and muscle and case for the peak pressure as a response. The Actuation is the fixed effect variable while the Foot is the random one.
fm0<-factorise(fit_model(npp,"PeakPressure",0,pLevel))
fm1<-factorise(fit_model(pp,"CoP",1,pLevel))
fm2<-factorise(fit_model(pp,"PeakLocation",1,pLevel))

# Converting to a wide format, so that I can use the different variables for the aesthetics of the plot
cop<-reshape(pp, idvar=c("Foot","Case","Muscle","Phase","Actuation"), timevar="Variable", varying=list(c('PP','CoPAP','CoPML','PLAP','PLML')), drop=c('Default','RawActiv'), direction="wide")
cop<-cop[complete.cases(cop),]

pressureDistribution<-merge(cop,npp,by=c('Foot','Case','Muscle','Phase','Actuation'))
pressureDistribution<-pressureDistribution[,c(seq(1,8),12)]
dimnames(pressureDistribution)[[2]][9]<-'PPnorm'
pressureDistribution<-pressureDistribution[,c(seq(1,6),9,seq(7,8))]
save('pressureDistribution',file=paste(outdirg,'pressureDistribution.RData',sep=''))

# Gathering the model estimates for drawing the predictor arrows
fm1r<-reshape(fm1, idvar=c("Phase","Muscle","Case","maxActiv"), timevar="Variable", direction="wide")
fm2r<-reshape(fm2, idvar=c("Phase","Muscle","Case","maxActiv"), timevar="Variable", direction="wide")
fm1r$p.star<-ifelse((fm1r$p.star.AP=="*"&fm1r$p.star.ML=="*"),"*"," ")
fm2r$p.star<-ifelse((fm2r$p.star.AP=="*"&fm2r$p.star.ML=="*"),"*"," ")

if (print) {
	cat(format(Sys.time(), "%H:%M:%S"),' Plotting figures\n')

	# Defining height and width for the output figures and plotting
	height<-10
	width<-8

	pdf(paste(outdirg,"Figures/muscleEffect.pdf",sep=''))
	p<-ggplot(npp, aes(Actuation, Value, color=Case))+geom_point()+
		geom_text(data=fm0, aes(x=8+as.numeric(Case), y=8, label=p.star), color=c("firebrick","darkblue"), size=8)+
		geom_segment(aes(x=0, y=Intercept, xend=maxActiv+1,
		yend=Intercept+Actuation*(maxActiv+1)), color=c("red",'darkblue'), size=1, data=fm0)+
		scale_y_continuous(name="Normalised peak pressure")+scale_x_continuous(name="Normalised muscle force")+
		theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
		theme(legend.title=element_text(size=20), legend.text=element_text(size=12))+
		facet_grid(Muscle ~ Phase)
	print(p)
	dev.off()

	pdf(paste(outdirg,"Figures/muscleCoP.pdf",sep=''))
	q<-ggplot(cop, aes(CoPML, CoPAP, color=Case))+geom_point(aes(alpha=Actuation))+
		scale_alpha_continuous(guide = guide_legend(title = "Actuation"))+
		theme_bw()+
		geom_text(data=fm1r, aes(label=ifelse(p.star.AP=="*",'A/P','')), x=-4, y=22, size=3, color='black')+
		geom_text(data=fm1r, aes(x=-7-3*as.numeric(Case), y=20, label=p.star.AP), color=c("firebrick","darkblue"), size=8)+
		geom_text(data=fm1r, aes(label=ifelse(p.star.ML=="*",'M/L','')), x=5, y=-18, size=3, color='black')+
		geom_text(data=fm1r, aes(x=7+3*as.numeric(Case), y=-20, label=p.star.ML), color=c("firebrick","darkblue"), size=8)+
		geom_segment(aes(x=Intercept.ML*ifelse((p.star.AP=="*"|p.star.ML=="*"),1,NaN), y=Intercept.AP, xend=Intercept.ML+Actuation.ML*sqrt(225/(2*(Actuation.ML^2+Actuation.AP^2))),
		yend=Intercept.AP+Actuation.AP*sqrt(225/(2*(Actuation.ML^2+Actuation.AP^2)))), color=c("red",'darkblue'), size=1.6, data=fm1r, arrow = arrow(length=unit(0.3,'cm')))+
		scale_x_continuous(name="CoP medial(-)/lateral(+) (mm)",limits=c(-16,16))+scale_y_continuous(name="CoP posterior(-)/anterior(+) (mm)", limits=c(-23,23))+
		theme(axis.title=element_text(size=20),axis.text=element_text(colour='black', size=12),strip.text=element_text(size=12))+
		theme(legend.title=element_text(size=20), legend.text=element_text(size=12))+
		facet_grid(Muscle ~ Phase)
	print(q)
	dev.off()

	pdf(paste(outdirg,"Figures/musclePP.pdf",sep=''))
	r<-ggplot(cop, aes(PLML, PLAP, color=Case))+geom_point(aes(alpha=Actuation))+
		scale_alpha_continuous(guide = guide_legend(title = "Actuation"))+
		geom_text(data=fm2r, aes(x=7+3*as.numeric(Case), y=20, label=p.star), color=c("firebrick","darkblue"), size=8)+
		geom_segment(aes(x=Intercept.ML*ifelse(p.star=="*",1,NaN), y=Intercept.AP, xend=Intercept.ML+Actuation.ML*10,
		yend=Intercept.AP+Actuation.AP*10), color=c("red",'darkblue'), size=1, data=fm2r, arrow = arrow(length=unit(0.3,'cm')))+
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
	fm0$p.value<-paste(fm0$p.value,fm0$p.star)
	fm1$p.value<-paste(fm1$p.value,fm1$p.star)

	# Rounding off to two digits and changing the column names for nicer printing
	sumTablePP<-tabular(Case*Muscle*Phase~Heading()*identity*Variable*(Intercept+Actuation+p.value), data=fm0)
	suppress<-latex(sumTablePP,paste(outdirg,"LaTeX/peakPressure.tex",sep=''))

	sumTableCoP<-tabular(Case*Muscle*Phase~Heading()*Variable*Heading()*Direction*Heading()*identity*(Intercept+Actuation+p.value), data=fm1)
	suppress<-latex(sumTableCoP,paste(outdirg,"LaTeX/Location.tex",sep=''), options=list(titlerule = '\\cline' ))

	sumTableForces<-tabular(Muscle*Phase~(Max+Initial)*PlusMinus(mean,sd), data=forces)
	suppress<-latex(sumTableForces,paste(outdirg,"LaTeX/Forces.tex",sep=''), options=list(titlerule = '\\cline' ),digit=0)
}