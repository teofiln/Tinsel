# Module UI

#' @title   mod_displayTree_ui and mod_displayTree_server
#' @description  A shiny Module. This module combines the tree with genetic distance as an S4 object that allows tree plotting and accessing the combined data. 
#'
#' @param id shiny id
#' @param input internal
#' @param output internal
#' @param session internal
#'
#' @rdname mod_displayTree
#'
#' @keywords internal
#' @export 
#' @importFrom shiny NS tagList 
mod_displayTree_ui <- function(id){
  ns <- NS(id)
  tagList(
  )
  
}

# Module Server

#' @rdname mod_displayTree
#' @export
#' @keywords internal

mod_displayTree_server <- function(input, output, session, 
                                   treeFileOut, geneFileCorOrUnOut, treeformat, lim, align, font, numscale, node, midP){
  ns <- session$ns
  
  midTree <- reactive({
    if(midP() == TRUE) {
      return(phytools::midpoint.root(treeFileOut()))
    }
    else {
      return(treeFileOut())
    }
  })

  #convert phylogenetic tree (midpoint rooted or not) to tibble to join tree and genetic distance matrix
  treeObject<-reactive({
    tibble::as_tibble(midTree())
  })

  #change column1, row1 to the id of label and replace - with a 0 within the file; necessary for downstream steps
  geneObject <- reactive({
    label <- . <- NULL
    dplyr::rename(geneFileCorOrUnOut(), label = 1)%>%
      replace(., .=="-", 0)
  })

  #join the treeobject and updated genetic distance file by label and convert to s4 object
  gandTS4 <- reactive({
    dplyr::full_join(treeObject(), geneObject(), by = "label")%>%
      treeio::as.treedata()
  })
  
  ## displayTree server functions
  treePlot <- function(inputFile){
    ggtree::ggtree(inputFile, layout = treeformat())+
      ggplot2::xlim(NA, lim())+
      ggtree::geom_tiplab(align = align(), fontface = font(), family="Helvetica") +
      ggtree::geom_treescale(width = numscale())+
      ggtree::geom_text2(ggplot2::aes(label=label, subset = !is.na(as.numeric(label)) & as.numeric(label) > node()), nudge_x = 0.00025)
  }
  
  #major plotting reactive using an S4 object called above (gandTS4) or the base midTree reactive made from import of treeFileOut and the  Upload data module 
  make_tree <- reactive({
    
    if(is.null(input$id)){ # this disconnects the need for genetic distance file to be uploaded. #not sure why I use input$id here 
      treePlot(midTree())
    } 
    else{
      treePlot(gandTS4())
    }
  })
  
  #return these reactive objects to be used in cladeAnnotator module 
  return(
    list(
      geneObjectOut = reactive(geneObject()),
      make_treeOut = reactive(make_tree())
    ))
}

## To be copied in the UI
# mod_displayTree_ui("displayTree_ui_1")

## To be copied in the server
# callModule(mod_displayTree_server, "displayTree_ui_1"