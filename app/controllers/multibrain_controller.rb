class MultibrainController < ApplicationController

  def index
    #Defaults

    @order = "line"
    
    if params[:order]
      @order = params[:order]
    end
    
    if @order == "gene"
      stacks_order = "lines.gene, stacks.id desc"
    elsif @order == "line"
      stacks_order = "lines.name, stacks.id desc"
    elsif @order == "name"
      stacks_order = "stacks.name, stacks.id desc"
    else
      #Date order
      stacks_order = "stacks.dateadded desc, stacks.id desc"
    end  
    
    @stacks = Stack.find(:all, :include => :line, :conditions => ['stacks.multibrain = true and lines.public = true and stacks.public = true'], :order => stacks_order)
    
  end
  
end
