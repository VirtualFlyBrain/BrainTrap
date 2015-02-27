class LineController < ApplicationController

#  before_filter :login_required

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @page = (params[:page] ||= 1).to_i
    lines_per_page = (params[:lpp] ||= 50).to_i
    offset = (@page - 1) * lines_per_page
    lines_order = "name"
    @keep_params = {};
    if params[:geneid]
      @gene = Gene.find(params[:geneid].to_i)
      @nlines = Line.count(:all, :include => :genes, :conditions => ['genes.id = ? and lines.public = true', params[:geneid].to_i])
      @npages = (@nlines / lines_per_page).ceil
      @lines = Line.find(:all, :include => :genes, :conditions => ['genes.id = ? and lines.public = true', params[:geneid].to_i], :limit => lines_per_page, :offset => offset)
      @keep_params = {:geneid => params[:geneid]};
    else
      @nlines = Line.count(:all, :conditions => ['lines.public = true'])
      @npages = (@nlines / lines_per_page).ceil
      @lines = Line.find(:all, :conditions => ['lines.public = true'], :order => lines_order, :limit => lines_per_page, :offset => offset)
    end

#    if params[:geneid]
#      @lines = Gene.find(params[:geneid].to_i).lines.find(:all)
#    else
#      @lines = Line.find(:all, :order => 'name')
#    end
    #@line_pages, @lines = paginate :lines, :order_by => "name", :per_page => 200
  end

  def show
    @line = Line.find(params[:id], :include => :genes, :conditions => ['lines.public = true'])
    @stacks = Stack.find(:all, :conditions => ['line_id = ? and public = true', @line.id])
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
