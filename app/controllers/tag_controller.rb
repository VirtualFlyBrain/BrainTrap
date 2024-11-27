class TagController < ApplicationController

  require 'BrainOntologyCache'

  def index
    redirect_to :controller => "welcome" unless logged_in?
    list
    render :action => 'list'
  end

  def list
    redirect_to :controller => "welcome" unless logged_in?
    @tag_pages, @tags = paginate :tags, :per_page => 10
  end

  def show
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.find(params[:id])
  end

  def new
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.new
    @tag.stack_id = Integer(params[:tag_stack_id])
    @stack = Stack.find(@tag.stack_id)
    @stackPrefix = DATA_IMAGE_FOLDER + "#{@stack[:name]}/"
        if @stack.num_channels == 1
      @channelMap = [['GFP', 'c1']]
    else
      @channelMap = [['Merged', 'merge'],['NC82', 'c1'],['GFP', 'c2']]
    end
    @img_dir = "/images/"
    #Edit in small size only
    @size = '512'
    @jumpMult = '1.0'
    if params[:jumpto] != nil
      @jumpto = Integer(params[:jumpto])
    end
    @search_dir = url_for :controller => 'search', :only_path => true, :trailing_slash => true
  end

  def create
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.new(params[:tag])
    @tag[:webuser_id] = current_user[:id]
    @tag[:user_id] = current_user[:id]
    if @tag.save
      ontology_terms = @tag.tag.scan(/\[([^\]]*)\]/)
      conn = ActiveRecord::Base.connection();
      ontology_terms.each do |term|
        fid = BrainOntologyCache.instance.term_to_fid(term[0])
        conn.execute "insert into tag_term (tag_id, term_id) values (#{@tag[:id]}, '#{fid}')"
      end
      flash[:notice] = 'Tag was successfully created.'
      redirect_to :controller => 'stack', :action => 'show', :id => @tag[:stack_id]
    else
      render :action => 'new'
    end
  end

  def edit
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.find(params[:id])
    @stack = Stack.find(@tag.stack_id)
    @stackPrefix = DATA_IMAGE_FOLDER + "#{@stack[:name]}/"
    if @stack.num_channels == 1
      @channelMap = [['GFP', 'c1']]
    else
      @channelMap = [['Merged', 'merge'],['NC82', 'c1'],['GFP', 'c2']]
    end
    @img_dir = "/images/"
    #Edit in small size only
    @size = '512'
    @jumpMult = '1.0'
    if @tag[:image_num] != nil
      @jumpto = Integer(@tag[:image_num])
      if @tag[:x_offset] != nil && @tag[:y_offset] != nil
        @circleX = @tag[:x_offset]
        @circleY = @tag[:y_offset]
      end
    end
    @search_dir = url_for :controller => 'search', :only_path => true, :trailing_slash => true
  end

  def update
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.find(params[:id])
    if @tag[:user_id] == current_user[:id] || current_user.admin
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Tag was successfully updated.'
        ontology_terms = @tag.tag.scan(/\[([^\]]*)\]/)
        conn = ActiveRecord::Base.connection();
        conn.execute "delete from tag_term where tag_id = #{@tag[:id]}"
        ontology_terms.each do |term|
          fid = BrainOntologyCache.instance.term_to_fid(term[0])
          conn.execute "insert into tag_term (tag_id, term_id) values (#{@tag[:id]}, '#{fid}')"
        end
        redirect_to :controller => 'stack', :action => 'show', :id => @tag[:stack_id]
      else
        render :action => 'edit'
      end
    else
      flash[:notice] = 'Wrong user - please create a new tag.'
      redirect_to :controller => 'stack', :action => 'show', :id => @tag[:stack_id]
    end
  end

  def destroy
    redirect_to :controller => "welcome" unless logged_in?
    @tag = Tag.find(params[:id])
    if @tag[:user_id] == current_user[:id] || current_user.admin
      @stack_id = @tag[:stack_id]
      #@tag.destroy
      @tag[:active] = false
      @tag.save
    else
      flash[:notice] = 'Wrong user.'
    end
    redirect_to :controller => 'stack', :action => 'show', :id => @stack_id
  end
end
