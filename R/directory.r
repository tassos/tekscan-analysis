OS <- .Platform$OS.type

if (OS == "windows") {
	outdir='~/PhD/Foot-ankle project/Measurements/Results Html/'
	outdirg='~/PhD/Submissions/Journals/Clinical Orthopaedics and Related Research/Figures/'
	indir='~/PhD/Foot-ankle project/Measurements/Voet 99/Results/'
}
if (OS =="unix") {
	outdir='~/Documents/PhD/Foot-ankle/RData/'
	outdirg='~/Documents/PhD/Foot-ankle/Journals/Clinical Orthopaedics and Related Research/Figures/'
	indir='~/Foot-ankle/Measurements/Voet 99/Results/'
}
