# Function for removing the unused labels from data frame columns
factorise <- function(x) {
	dfClass<-sapply(x, class)
	for (i in 1:ncol(x)) {
		if (dfClass[i] == 'factor') {
			x[[i]]<-factor(x[[i]])
		}
		if (dfClass[i] == 'character') {
			x[[i]]<-as.factor(x[[i]])
		}
	}
	return(x)
}

# Function for adding a new column in the data frame based on the phases that the measurement occured.
splitToPhases<-function(x,phases) {
	x$Phase<-1
	for (i in phases){
		x$Phase<-ifelse(as.numeric(as.character(x$Percentage)) >i,x$Phase+1,x$Phase)
	}
	x$Phase<-factor(x$Phase)

	lvls<-vector()
	for (i in seq(1,length(phases)-1)) {
		lvls[i]<-paste(phases[i]+1,"-",phases[i+1],sep='')
	}
	levels(x$Phase)<-lvls
	return(x)
}

# Define the statistical test function. Due to the fact that sometimes, values might be missing, we need to make sure that the function
# will always return a value. That's why we use the failwith function.
wilTest<- function(x,var,grp,lvl1,lvl2) {
	return(wilcox.test(x[,var][x[,grp]==lvl1], x[,var][x[,grp]==lvl2], alternative="two.sided", paired=F, conf.int=T, na.action= na.omit))
}
safewilTest <- failwith(vector("list",9), wilTest, quiet=T)
