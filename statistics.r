# Define the statistical test function. Due to the fact that sometimes, values might be missing, we need to make sure that the function
# will always return a value. That's why we use the failwith function.
wilTest<- function(x,var,grp,lvl1,lvl2) {
	return(wilcox.test(x[,var][x[,grp]==lvl1], x[,var][x[,grp]==lvl2], alternative="two.sided", paired=F, conf.int=T, na.action= na.omit))
}
safewilTest <- failwith(vector("list",9), wilTest, quiet=T)

difference<-function(x,y){
	return(x-y)
}

relative<-function(x,y){
	return((x/y)-1)
}

breakDown<-function(x){
	a<-nrow(x[x$V1.x == TRUE & x$V1.y == TRUE,])
	b<-nrow(x[x$V1.x == TRUE & x$V1.y == FALSE,])
	c<-nrow(x[x$V1.x == FALSE & x$V1.y == FALSE,])
	d<-nrow(x[x$V1.x == FALSE & x$V1.y == TRUE,])
	return(c(a,b,c,d))
}

peakDetect <- function(x,scope) {	
	maxV1<-max(x$Value[1:scope])
	maxV2<-max(x$Value[(scope+1):length(x$Value)])
	maxL1<-as.numeric(x$Percentage[x$Value == maxV1])
	maxL2<-as.numeric(x$Percentage[x$Value == maxV2])
	minV<-min(x$Value[maxL1:maxL2])
	minL<-as.numeric(x$Percentage[x$Value == minV])
	return(data.frame(Peak=c("max1","min","max2"),Value=c(maxV1,minV,maxV2),Percentage=c(maxL1,minL,maxL2)))
}

normWeight <- function(x,y,w,m) {
	t<-1
	if (y <= 10) {
		t<-(0.5*y**2)/(y**2-10*y+50)
	}
	if (y >= 90) {
		t<-(0.5*(y-100)**2)/(y**2-190*y+9050)
	}
	x<-(x-w*t)/m+t
	return(x)
}

normWeight2 <- function(x,y,w,m) {
	t<-1
	if (y <= 16) {
		t<-(0.5*y**2)/(y**2-16*y+128)
	}
	if (y >= 84) {
		t<-(0.5*(y-100)**2)/(y**2-184*y+8528)
	}
	x<-(x-w*t)/m+t
	return(x)
}

rSqrt <- function(x,var,lvl1,lvl2,rnd) {
	A<-data.frame(var=lvl2,Value=round(summary(lm(x$V1[x[,var]==lvl1]~x$V1[x[,var]==lvl2]))$r.squared,rnd))
	colnames(A)[1]<-var
	return(A)
}

#Calculating R^2 within each measurement group/case (for repeatability within each case)
rSqrtM<-function(x) {
	sbst<-cast(x, Percentage~Repetition, value="Value")[,-1]
	mean_run<-rowMeans(sbst,na.rm=T)
	mean_all<-mean(mean_run,na.rm=T)
	nomin<-sum((sbst-mean_run)^2)/(dim(sbst)[1]*(dim(sbst)[2]-1))
	denom<-sum((sbst-mean_all)^2)/(dim(sbst)[2]*dim(sbst)[1]-1)
	return(data.frame(Value=abs(1-(nomin/denom))))
}

splitToPhases<-function(x,phases) {
x$Phase<-1
for (i in phases){
	x$Phase<-ifelse(as.numeric(as.character(x$Percentage)) >i,x$Phase+1,x$Phase)
}
x$Phase<-factor(x$Phase)
return(x)
}

normPressure <- function(x) {
	x<-ddply(x,.(Percentage), function(y) data.frame(Value=y$Value/max(x$Value)))
}