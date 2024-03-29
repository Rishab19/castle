# tested on R 3.4.3
# setup required libraries and constants
library(scater)  # tested on version 1.6.3,    install from Bioconductor: source("https://bioconductor.org/biocLite.R"); biocLite("scater")
library(igraph)  # tested on version 1.2.1,   install from CRAN: install.packages("igraph")
library(xgboost) # tested on version 0.6.4.1, install from CRAN: install.packages("xgboost")

BREAKS=c(-1, 0, 1, 6, Inf)
nFeatures = 100
source_path <- "/home/rishab20213/caSTLe_data/xin/"
target_path <- "/home/rishab20213/caSTLe_data/seger/"
# 1. Load datasets in scater format: loaded files expected to contain "Large SingleCellExperiment" object
source = readRDS(paste(source_path,"source.rds",sep=""))
target = readRDS(paste(target_path,"target.rds",sep=""))
ds1 = t(exprs(source)) 
ds2 = t(exprs(target)) 
colnames(ds1) = elementMetadata(source)$feature_symbol
colnames(ds2) = elementMetadata(target)$feature_symbol
sourceCellTypes = as.factor(colData(source)$cell_type1)


# remove unlabeled from source
unknownLabels = levels(sourceCellTypes)[grep("not applicable|unclassified|contaminated|unknown", levels(sourceCellTypes))]
if (length(unknownLabels)>0) {
  hasKnownLabel = is.na(match(sourceCellTypes, unknownLabels))
  sourceCellTypes = sourceCellTypes[hasKnownLabel]
  sourceCellTypes = as.factor(as.character(sourceCellTypes))
  ds1 = ds1[hasKnownLabel,]
}

# 2. Unify sets, excluding low expressed genes
source_n_cells_counts = apply(exprs(source), 1, function(x) { sum(x > 0) } )
target_n_cells_counts = apply(exprs(target), 1, function(x) { sum(x > 0) } )
common_genes = intersect( colnames(ds1)[source_n_cells_counts>10], 
                          colnames(ds2)[target_n_cells_counts>10]
)
remove(source_n_cells_counts, target_n_cells_counts)
ds1 = ds1[, colnames(ds1) %in% common_genes]
ds2 = ds2[, colnames(ds2) %in% common_genes]
ds = rbind(ds1[,common_genes], ds2[,common_genes])
isSource = c(rep(TRUE,nrow(ds1)), rep(FALSE,nrow(ds2)))
remove(ds1, ds2)

# 3. Highest mean in both source and target
topFeaturesAvg = colnames(ds)[order(apply(ds, 2, mean), decreasing = T)]

# for each cell - what is the most probable classification?
L = length(levels(sourceCellTypes))
targetClassification = as.data.frame(matrix(rep(0,L*sum(!isSource)), nrow=L), row.names = levels(sourceCellTypes))


# iterate over all source cell types
for (cellType in levels(sourceCellTypes)) {
  
  inSourceCellType = as.factor(ifelse(sourceCellTypes == cellType, cellType, paste0("NOT",cellType)))
  
  # 4. Highest mutual information in source
  topFeaturesMi = names(sort(apply(ds[isSource,],2,function(x) { compare(cut(x,breaks=BREAKS),inSourceCellType,method = "nmi") }), decreasing = T))
  
  # 5. Top n genes that appear in both mi and avg
  selectedFeatures = union(head(topFeaturesAvg, nFeatures) , head(topFeaturesMi, nFeatures) )
  
  # 6. remove correlated features
  tmp = cor(ds[,selectedFeatures], method = "pearson")
  tmp[!lower.tri(tmp)] = 0
  selectedFeatures = selectedFeatures[apply(tmp,2,function(x) any(x < 0.9))]
  remove(tmp)
  
  # 7,8. Convert data from continous to binned dummy vars
  # break datasets to bins
  dsBins = apply(ds[, selectedFeatures], 2, cut, breaks= BREAKS)
  # use only bins with more than one value
  nUniq = apply(dsBins, 2, function(x) { length(unique(x)) })
  # convert to dummy vars
  ds0 = model.matrix(~ . , as.data.frame(dsBins[,nUniq>1]))
  remove(dsBins, nUniq)

  cat(paste0("<h2>Classifier for ",cellType,"</h2>"))
  
  inTypeSource = sourceCellTypes == cellType
  # 9. Classify
  xg=xgboost(data=ds0[isSource,] , 
             label=inTypeSource,
             objective="binary:logistic", 
             eta=0.7 , nthread=1, nround=20, verbose=0,
             gamma=0.001, max_depth=5, min_child_weight=10)

  # 10. Predict
  inTypeProb = predict(xg, ds0[!isSource, ])
  
  targetClassification[cellType,] = inTypeProb
  
  
}

# use the targetClassification values to determine the predicted cell type for each cell in the target dataset
# see "EvaluateCaSTLePerCellType.R" for an example

 
