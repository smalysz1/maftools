#' Plot Transition and Trasnversion ratios.
#' @description Takes results generated from \code{titv} and plots the Ti/Tv ratios and contributions of 6 mutational conversion classes in each sample.
#'
#' @param res results generated by \code{\link{titv}}
#' @param plotType Can be 'bar', 'box' or 'both'. Defaults to 'both'
#' @param color named vector of colors for each coversion class.
#' @param showBarcodes Whether to include sample names for barplot
#' @param sampleOrder Sample names in which the barplot should be ordered. Default NULL
#' @param textSize fontsize if showBarcodes is TRUE. Deafult 2.
#' @param baseFontSize font size. Deafult 1.
#' @param axisTextSize text size x and y tick labels. Default c(1,1).
#' @param plotNotch logical. Include notch in boxplot.
#' @return None.
#' @seealso \code{\link{titv}}
#' @examples
#' laml.maf <- system.file("extdata", "tcga_laml.maf.gz", package = "maftools")
#' laml <- read.maf(maf = laml.maf)
#' laml.titv = titv(maf = laml, useSyn = TRUE)
#' plotTiTv(laml.titv)
#'
#' @export


plotTiTv = function(res = NULL, plotType = 'both', sampleOrder = NULL,
                    color = NULL, showBarcodes = FALSE, textSize = 0.8, baseFontSize = 1,
                    axisTextSize = c(1, 1), plotNotch = FALSE){

  if(is.null(color)){
    col = get_titvCol(alpha = 0.8)
  }else{
    col = color
  }

  titv.frac = res$fraction.contribution
  titv.frac.melt = data.table::melt(data = titv.frac, id = 'Tumor_Sample_Barcode')
  conv.class = c('Ti', 'Ti', 'Tv', 'Tv', 'Tv', 'Tv')
  names(conv.class) = c("T>C", "C>T", "T>A", "T>G", "C>A", "C>G")
  titv.frac.melt$TiTv = conv.class[as.character(titv.frac.melt$variable)]

  titv.contrib = suppressMessages(data.table::melt(res$TiTv.fractions, id = 'Tumor_Sample_Barcode'))
  titv.frac.melt$variable = factor(x = titv.frac.melt$variable,
                                   levels = c("T>C", "C>T", "T>A", "T>G", "C>A", "C>G"))

  titv.order = titv.frac.melt[,mean(value), by = .(variable)]
  titv.order = titv.order[order(V1, decreasing = TRUE)]
  orderlvl = as.character(titv.order$variable)
  titv.frac.melt$variable = factor(x = titv.frac.melt$variable, levels = orderlvl)

  tf = res$TiTv.fractions
  data.table::setDF(x = tf)
  rownames(tf) = tf$Tumor_Sample_Barcode
  tf = tf[,-1]


  if(plotType == 'bar'){

    titv.frac.melt = data.table::dcast(data = titv.frac.melt, variable ~ Tumor_Sample_Barcode)
    data.table::setDF(x = titv.frac.melt)
    rownames(titv.frac.melt) = titv.frac.melt$variable
    titv.frac.melt = as.matrix(titv.frac.melt[,-1])

    if(length(which(colSums(titv.frac.melt) == 0)) > 0){
      titv.frac.melt = titv.frac.melt[,-which(colSums(titv.frac.melt) == 0), drop = FALSE]
    }

    if(showBarcodes){
      par(mar = c(6, 4, 3, 3))
    }else{
      par(mar = c(2, 4, 3, 3))
    }

    if(!is.null(sampleOrder)){
      sampleOrder = sampleOrder[sampleOrder %in% colnames(titv.frac.melt)]
      if(length(sampleOrder) == 0){
        stop("Sample names do not match")
      }
      titv.frac.melt = titv.frac.melt[,sampleOrder]
    }

    b = barplot(titv.frac.melt, col = col[rownames(x = titv.frac.melt)],
                names.arg = rep("", ncol(titv.frac.melt)),
                axes = FALSE, space = 0.2, border = NA, lwd = 1.2)
    if(showBarcodes){
      axis(side = 1, at = b, labels = colnames(titv.frac.melt), tick = FALSE, font = 1, line = -1, las = 2, cex.axis = textSize)
    }
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2])
    mtext(side = 2, text = "% Mutations", font = 1, cex = baseFontSize, line = 2.5)

    add_legend(x = "topright", legend = names(col), col = col, bty = "n", pch = 15, y.intersp = 0.7, text.font = 1)

  } else if(plotType == 'box'){
    layout(matrix(data = c(1, 2), nrow = 1), widths = c(4, 2))
    par(mar = c(2, 4, 2, 2))
    b = boxplot(value ~ variable, data = titv.frac.melt, axes = FALSE, xlab = "", ylab = "", col = col[levels(titv.frac.melt[,variable])],
                names=NA, lty = 1, staplewex = 0, pch = 16, xaxt="n", notch = plotNotch,
                outcex = 0.6, outcol = "gray70", ylim = c(0, 100), lwd = 0.6)
    axis(side = 1, at = 1:length(levels(titv.frac.melt[,variable])), labels = levels(titv.frac.melt[,variable]),
         tick = FALSE, font = 1, line = -1, cex.axis = axisTextSize[1])
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2])
    mtext(side = 2, text = "% Mutations", font = 1, cex = baseFontSize, line = 2.5)

    par(mar = c(2, 1.5, 2, 2))
    b = boxplot(tf, axes = FALSE, xlab = "", ylab = "", col = 'gray70',
                names=NA, lty = 1, staplewex = 0, pch = 16, xaxt="n", notch = plotNotch,
                outcex = 0.6, outcol = "gray70", ylim = c(0, 100), lwd = 0.6)
    axis(side = 1, at = 1:2, labels = names(tf), tick = FALSE, font = 1, line = -1, cex.axis = axisTextSize[1])
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2])

  } else if(plotType == 'both'){

    layout(mat = matrix(data = c(1, 2, 3, 3), byrow = TRUE, nrow = 2), widths = c(4, 2), heights = c(5, 4))
    par(mar = c(2, 4, 2, 1))
    plot(NA, axes = FALSE, xlim = c(0.25, 6.25), ylim = c(0, 100), xlab = NA, ylab = NA)
    abline(h = seq(0, 100, 25), v = 1:6, col = grDevices::adjustcolor(col = "gray70", alpha.f = 0.5), lty = 2, lwd = 0.6)
    b = boxplot(value ~ variable, data = titv.frac.melt, axes = FALSE, xlab = "", ylab = "", col = col[levels(titv.frac.melt[,variable])],
                names=NA, lty = 1, staplewex = 0, pch = 16, xaxt="n", notch = plotNotch,
                outcex = 0.6, outcol = "gray70", ylim = c(0, 100), lwd = 0.6, add = TRUE)
    axis(side = 1, at = 1:length(levels(titv.frac.melt[,variable])), labels = levels(titv.frac.melt[,variable]), tick = FALSE, font = 1, line = -1, cex.axis = axisTextSize[1])
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2], line = 0.4)
    mtext(side = 2, text = "% Mutations", font = 1, cex = baseFontSize, line = 2.5)

    par(mar = c(2, 1.5, 2, 2))
    plot(NA, axes = FALSE, xlim = c(0, 3), ylim = c(0, 100), xlab = NA, ylab = NA)
    abline(h = seq(0, 100, 25), v = 1:2,
           col = grDevices::adjustcolor(col = "gray70", alpha.f = 0.5), lty = 2, lwd = 0.6)
    b = boxplot(tf, axes = FALSE, xlab = "", ylab = "", col = 'gray70',
                names=NA, lty = 1, staplewex = 0, pch = 16, xaxt="n", notch = plotNotch,
                outcex = 0.6, outcol = "gray70", ylim = c(0, 100), lwd = 0.6, add = TRUE, at = 1:2)
    axis(side = 1, at = 1:2, labels = names(tf), tick = FALSE, font = 1, line = -1, cex.axis = axisTextSize[1])
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2])

    titv.frac.melt = data.table::dcast(data = titv.frac.melt, variable ~ Tumor_Sample_Barcode)
    data.table::setDF(x = titv.frac.melt)
    rownames(titv.frac.melt) = titv.frac.melt$variable
    titv.frac.melt = as.matrix(titv.frac.melt[,-1])

    if(length(which(colSums(titv.frac.melt) == 0)) > 0){
      titv.frac.melt = titv.frac.melt[,-which(colSums(titv.frac.melt) == 0), drop = FALSE]
    }

    if(showBarcodes){
      par(mar = c(6, 4, 1, 1))
    }else{
      par(mar = c(2, 4, 1, 1))
    }

    if(!is.null(sampleOrder)){
      sampleOrder = sampleOrder[sampleOrder %in% colnames(titv.frac.melt)]
      if(length(sampleOrder) == 0){
        stop("Sample names do not match")
      }
      titv.frac.melt = titv.frac.melt[,sampleOrder]
    }

    b = barplot(titv.frac.melt, col = col[rownames(x = titv.frac.melt)], names.arg = rep("", ncol(titv.frac.melt)),
                axes = FALSE, space = 0.2, border = NA)
    if(showBarcodes){
      axis(side = 1, at = b, labels = colnames(titv.frac.melt), tick = FALSE, font = 1, line = -1, las = 2, cex.axis = textSize)
    }
    axis(side = 2, at = seq(0, 100, 25), las = 2, font = 1, lwd = 1.2, cex.axis = axisTextSize[2])
    mtext(side = 2, text = "% Mutations", font = 1, cex = baseFontSize, line = 2.5)

  }else{
    stop('plotType can only be bar, box or both')
  }
}
