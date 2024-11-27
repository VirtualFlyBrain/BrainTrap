class LineController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @page = (params[:page] ||= 1).to_i
    lines_per_page = (params[:lpp] ||= 50).to_i
    offset = (@page - 1) * lines_per_page
    lines_order = "name"
    @keep_params = {};
    if params[:geneid]
      @gene = Gene.find(params[:geneid].to_i)
      @nlines = Line.count_by_sql "select count(*) from lines left join genes_lines on (lines.id = genes_lines.line_id) where lines.public = true and genes_lines.gene_id = #{params[:geneid].to_i}"
      @npages = (@nlines / lines_per_page).ceil
      @lines = Line.find_by_sql "select lines.* from lines left join genes_lines on (lines.id = genes_lines.line_id) left join genes on (genes_lines.gene_id = genes.id) where lines.public = true and genes.id = #{params[:geneid].to_i} limit #{lines_per_page} offset #{offset}"
      @keep_params = {:geneid => params[:geneid]};
    else
      @nlines = Line.where(:public => true).count
      @npages = (@nlines / lines_per_page).ceil
      @lines = Line.where(:public => true).order(lines_order).limit(lines_per_page).offset(offset)
    end
  end

  def show
    @line = Line.where("lines.public = true and lines.id = ?", params[:id]).joins(:genes).take
    @stacks = Stack.where("stacks.public = true and stacks.line_id = ?", @line.id)
  end

  def new
    redirect_to :controller => "welcome" unless logged_in?
    @line = Line.new
  end

  def create
    redirect_to :controller => "welcome" unless logged_in?
    @line = Line.new(params[:line])
    if @line.save
      flash[:notice] = 'Line was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    redirect_to :controller => "welcome" unless logged_in?
    @line = Line.find(params[:id])
  end

  def update
    redirect_to :controller => "welcome" unless logged_in?
    @line = Line.find(params[:id])
    if @line.update_attributes(params[:line])
      flash[:notice] = 'Line was successfully updated.'
      redirect_to :action => 'show', :id => @line
    else
      render :action => 'edit'
    end
  end

  def destroy
    redirect_to :controller => "welcome" unless logged_in?
    Line.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
