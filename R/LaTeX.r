insert.headers <- function (x) {
	Headers<-paste("\\documentclass[11pt,twoside,a4paper]{article}","\\usepackage{rotating}","\\begin{document}",sep="\n")
	Footers<-"\\end{document}"
	x<-paste(Headers,x,Footers, sep="\n")
	return(x)
}