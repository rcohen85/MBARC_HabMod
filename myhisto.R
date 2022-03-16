#created by MAZ on 3/15/22 to add a histogram of the underlying data to a partial residual plot produced 
#by modelling

#This function takes as input your underlying data (xvals), the min/max of 
#the plot you want to add the histogram to (miny, maxy), and the range of your xvalues
#as an example: for hour of day, your underlying data might be xvals  = 23,0,0,1,2,3, the y limits of 
#your plot might be c(0,1), and the range would be c(0,23)

myhisto<-function(xvals,miny,maxy,range){
  x = seq(from = range[1],to = range[2],by = 1)
  fullhist = hist(xvals,x)
  yhist = fullhist$counts
  #normalize it to be @ most half as high as y scale
  ymod = yhist/(max(yhist)-miny)
  newy = ymod/4
  data.frame(x=x[-1],y=newy)
}


#the output of the function can be easily added to a ggplot using code similar to the following
# ggplot()+
#   geom_bar(data = violinrug,aes(x=x,y=y),stat = "identity",fill=rgb(0,0.5,0.5,alpha=0.3))

#or something similar to that. Please message Morgan with questions!