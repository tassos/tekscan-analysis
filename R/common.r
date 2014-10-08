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

classify <- function(x,dividers,labels) {
	dividers<-c(-Inf,dividers,+Inf)
	p<-array()
	for (j in 1:length(x)) {
		for (i in 1:(length(dividers)-1)){
			if (x[j] >= dividers[i] & x[j] < dividers[i+1]){
				p[j] = labels[i]
			}
		}
	}
	y <- as.data.frame(matrix(ncol=length(labels), dimnames=list(NULL,labels)))
	for (k in 1:length(labels)){
		y[[labels[k]]]<-sum(p == labels[k])
	}
	return(y)
}

# Calculating cohens_d for the power analysis
cohens_d <- function(x, y) {
    lx <- length(x)- 1
    ly <- length(y)- 1
    md  <- abs(mean(x) - mean(y))        ## mean difference (numerator)
    csd <- lx * var(x) + ly * var(y)
    csd <- csd/(lx + ly)
    csd <- sqrt(csd)                     ## common sd computation

    cd  <- md/csd                        ## cohen's d
}

# Function for producing the graphs of the fourth article on peak pressure distribution
# It takes two png files, merges them in an svg and then exports that to a png. Neat eh?
save_png <- function(height,width,bone,filename) {
	x<- paste('<svg version="1.2" width="',width+50,'pt" height="',height-100,'pt" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n',
	' <image height="',height,'" width="',width,'" x="200" xlink:href="Area_Time_',bone,'.png" y="0"/>',
	' <image height="200" width="200.0" x="0" xlink:href="',bone,' bottom.png" y="',(height-200)/2,'"/>',
	'</svg>',sep='')

	write(x,file=paste(filename,bone,'.svg',sep=''))

	OS <- .Platform$OS.type
	if (OS=="windows") {
		magickPath<-'c:/"Program Files"/ImageMagick/6.8.9-Q16/'
	}
	if (OS=="unix") {
		magickPath<-''
	}

	shell(paste(magickPath,'convert "',filename,bone,'.svg" "',filename,bone,'.png"',sep=''))
}

fit_model <- function(data, var_string, location,pLevel) {
	if (location==1) {
		var_string<-c(paste(var_string,"A/P"),paste(var_string,"M/L"))
	}
	data<-subset(data,Variable %in% var_string)
	fm<-dlply(data,.(Variable,Phase,Muscle,Case), function(x) lme(Value ~ Activation,data = x,~1 | Foot))
	fm.coef<-ldply(fm,function(x) c(fixef(x),summary(x)$tTable['Activation','p-value'],max(x$data$Activation),sqrt(mean(x$residuals[,1]^2))))
	if (location==1) {
		fm.coef$Variable<-mapvalues(fm.coef$Variable,from=var_string, to=c("AP","ML"))
	}
	fm.coef[,c(5,6,7,8)]<-round(fm.coef[,c(5,6,7,8)],3)
	dimnames(fm.coef)[[2]][c(5,7,8,9)]<-c('Intercept','p.value','maxActiv','r^2')
	fm.coef$p.star<-ifelse(fm.coef$p.value <=pLevel,"*"," ")
	return(fm.coef)
}