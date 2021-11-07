### DATA
base_path <- "/home/rishab20213/caSTLe_data/human_pancreas/"
d <- read.table(base_path+"data.txt", header = T)
genes <- read.csv(base_path+"human_gene_annotation.csv", header = T)
rownames(d) <- genes[,2]
d <- d[,2:ncol(d)]

### ANNOTATIONS
ann <- read.table(base_path+"human_islet_cell_identity.txt", header = T, sep = "\t", stringsAsFactors = F)
rownames(ann) <- ann[,1]
rownames(ann) <- gsub(" ", "_", rownames(ann))
ann <- ann[,9:ncol(ann)]
colnames(ann)[length(colnames(ann))] <- "cell_type1"
# format cell type names
ann$cell_type1[ann$cell_type1 == "PP"] <- "gamma"
ann$cell_type1[ann$cell_type1 == "PP.contaminated"] <- "gamma.contaminated"

### SINGLECELLEXPERIMENT
sce_path <- "/home/rishab20213/caSTLe_data/"
source(sce_path+"castle/create_sce.R")
sceset <- create_sce_from_normcounts(d, ann)
# saveRDS(sceset, "xin.rds")
save_path <- "/home/rishab20213/caSTLe_data/xin/"
saveRDS(sceset, save_path+"source.rds")
