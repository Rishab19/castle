### DATA
base_path <- "/home/rishab20213/caSTLe_data/human_pancreas/"
d <- read.table(paste(base_path,"pancreas_refseq_rpkms_counts_3514sc.txt",sep=""), stringsAsFactors = F)
d <- d[!duplicated(d[,1]), ]
rownames(d) <- d[,1]
d <- d[,3:ncol(d)]
d <- d[,3515:7028]
labs <- read.table(paste(base_path,"labels.txt",sep=""), stringsAsFactors = F, header = F)
labs <- as.character(labs)
colnames(d) <- labs
d <- d[,order(colnames(d))]
# remove eGFP row
d <- d[1:(nrow(d) - 1), ]

### ANNOTATIONS
ann <- read.table(paste(base_path,"E-MTAB-5061.sdrf.txt",sep=""), stringsAsFactors = F, header = T, sep = "\t")
rownames(ann) <- ann$Extract.Name
ann <- ann[order(rownames(ann)), ]
ann <- ann[,7:11]
colnames(ann) <- c("cell_quality", "cell_type1", "disease", "sex", "age")
# format cell type names
ann$cell_type1 <- unlist(lapply(strsplit(ann$cell_type1, " cell"), "[[", 1))
sce_path <- "/home/rishab20213/caSTLe_data/"
### SINGLECELLEXPERIMENT
source(paste(sce_path,"castle/create_sce.R",sep=""))
sceset <- create_sce_from_counts(d, ann)
# saveRDS(sceset, "segerstolpe.rds")
save_path <- "/home/rishab20213/caSTLe_data/seger/"
saveRDS(sceset, paste(save_path,"target.rds",sep=""))
