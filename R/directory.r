OS <- .Platform$OS.type

if (OS == "windows") {
	outdir='~/PhD/Foot-ankle project/Measurements/Results Html/'
	outdirg='c:/Users/u0074517/Documents/PhD/Submissions/Journals/'
	indir='~/PhD/Foot-ankle project/Measurements/Voet 99/Results/'
}
if (OS =="unix") {
	outdir='~/Documents/PhD/Foot-ankle/RData/'
	outdirg='~/Documents/PhD/Foot-ankle/Journals/'
	indir='~/Foot-ankle/Measurements/Voet 99/Results/'
}
