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

## Summarizes data.
## http://www.cookbook-r.com/Manipulating_data/Summarizing_data/
## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
    require(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This does the summary. For each group's data frame, return a vector with
    # N, mean, and sd
    datac <- ddply(data, groupvars, .drop=.drop,
      .fun = function(xx, col) {
        c(N    = length2(xx[[col]], na.rm=na.rm),
          mean = mean   (xx[[col]], na.rm=na.rm),
          sd   = sd     (xx[[col]], na.rm=na.rm)
        )
      },
      measurevar
    )

    # Rename the "mean" column    
    datac <- rename(datac, c("mean" = measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval: 
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}
