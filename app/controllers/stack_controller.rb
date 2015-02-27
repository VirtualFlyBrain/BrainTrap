class StackController < ApplicationController

  layout "stack", :except => [:show, :multistack]
  
  #  before_filter :login_required
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

  def list
    #Defaults
    @show = "45"
    @order = "date"
    
    @page = (params[:page] ||= 1).to_i
    
    stacks_per_page = 45.0
    if params[:show]
      @show = params[:show]
      if params[:show] == "all"
        stacks_per_page = 1e5
      else
        stacks_per_page = params[:show].to_i
      end
    end
    
    offset = (@page - 1) * stacks_per_page
    
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
    
    @keep_params = {:order => params[:order], :show => params[:show]};
    #    if params[:stack_line_id] != nil
    #      line_number = Integer(params[:stack_line_id])
    #      @stack_pages, @stacks = paginate :stacks, :conditions => "line_id = #{line_number}", :order_by => stacks_order, :per_page => staks_per_page
    if params[:untagged]
      @nstacks = Stack.count_by_sql("select count(*) from stacks left join tags on (stacks.id = tags.stack_id and tags.active = true) join lines on (stacks.line_id = lines.id) where tags.id is null and lines.public = true and stacks.public = true")
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find_by_sql("select stacks.* from stacks left join tags on (stacks.id = tags.stack_id and tags.active = true) join lines on (stacks.line_id = lines.id) where tags.id is null and lines.public = true and stacks.public = true order by #{stacks_order} limit #{stacks_per_page} offset #{offset}")
      @keep_params = {:untagged => 1}
    elsif params[:untagged_by_me]
      @nstacks = Stack.count_by_sql("select count(*) from stacks left join tags on (stacks.id = tags.stack_id and tags.active = true and tags.user_id = #{current_user.id}) join lines on (stacks.line_id = lines.id) where tags.id is null and lines.public = true and stacks.public = true")
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find_by_sql("select stacks.* from stacks left join tags on (stacks.id = tags.stack_id and tags.active = true and tags.user_id = #{current_user.id}) join lines on (stacks.line_id = lines.id) where tags.id is null and lines.public = true and stacks.public = true order by #{stacks_order} limit #{stacks_per_page} offset #{offset}")
      @keep_params = {:untagged_by_me => 1}
    elsif params[:geneid]
      @gene = Gene.find(params[:geneid].to_i)
      @nstacks = Stack.count(:all, :include => [{:line => :genes}], :conditions => ['genes.id = ? and lines.public = true and stacks.public = true', params[:geneid].to_i])
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find(:all, :include => [{:line => :genes}], :conditions => ['genes.id = ? and lines.public = true and stacks.public = true', params[:geneid].to_i], :order => stacks_order, :limit => stacks_per_page, :offset => offset)
      @keep_params = {:geneid => params[:geneid]};
    elsif params[:fbgn]
      @gene = Gene.find(:first, :conditions => ['genes.genefbgn = ?', params[:fbgn]])
      @nstacks = Stack.count(:all, :include => [{:line => :genes}], :conditions => ['genes.genefbgn = ? and lines.public = true and stacks.public = true', params[:fbgn]])
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find(:all, :include => [{:line => :genes}], :conditions => ['genes.genefbgn = ? and lines.public = true and stacks.public = true', params[:fbgn]], :order => stacks_order, :limit => stacks_per_page, :offset => offset)
      @keep_params = {:fbgn => params[:fbgn]};
    elsif params[:stack_line_id]
      @line = Line.find(params[:stack_line_id].to_i, :conditions => 'public = true')
      @nstacks = Stack.count(:all, :include => :line, :conditions => ['lines.id = ? and lines.public = true and stacks.public = true', params[:stack_line_id].to_i])
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find(:all, :include => :line, :conditions => ['lines.id = ? and lines.public = true and stacks.public = true', params[:stack_line_id].to_i], :order => stacks_order, :limit => stacks_per_page, :offset => offset)
      @keep_params = {:stack_line_id => params[:stack_line_id]};
    elsif params[:cpti]
      @line = Line.find(:first, :conditions => ['lines.name = ? and public = true', params[:name].to_i])
      @nstacks = Stack.count(:all, :include => :line, :conditions => ['lines.name = ? and lines.public = true and stacks.public = true', params[:cpti]])
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find(:all, :include => :line, :conditions => ['lines.name = ? and lines.public = true and stacks.public = true', params[:cpti]], :order => stacks_order, :limit => stacks_per_page, :offset => offset)
      @keep_params = {:cpti => params[:cpti]};
    else
      @nstacks = Stack.count(:all, :include => :line, :conditions => ['lines.public = true and stacks.public = true'])
      @npages = (@nstacks / stacks_per_page).ceil
      @stacks = Stack.find(:all, :include => :line, :conditions => ['lines.public = true and stacks.public = true'], :order => stacks_order, :limit => stacks_per_page, :offset => offset)
    end
  end

  def show
    @stack = Stack.find(params[:id], :include => [{:line => :genes}], :conditions => 'public = true')
    @stackPrefix = DATA_IMAGE_FOLDER + "#{@stack[:name]}/"
    if @stack.num_channels == 1
      @channelMap = [['GFP', 'c1']]
    else
      @channelMap = [['Merged', 'merge'],['NC82', 'c1'],['GFP', 'c2']]
    end
    @img_dir = url_for :controller => 'images', :only_path => true, :trailing_slash => true
    case params[:size]
    when 'full'
      @size = 'full'
      @jumpMult = (@stack.max_res_x / 512.0).to_s
    when '768'
      @size = '768'
      @jumpMult = '1.5'
    else
      @size = '512'
      @jumpMult = '1.0'
    end
  end

  def multistack
    @cmy = params[:cmy] != nil
    @invert = params[:invertoff] == nil && params[:invert] != nil
    if params[:random] != nil
      allstacks = Stack.find(:all, :conditions => 'stacks.multibrain = true and public = true')
      params[:c1] = allstacks[rand(allstacks.length)][:id]
      params[:c2] = allstacks[rand(allstacks.length)][:id]
      params[:c3] = allstacks[rand(allstacks.length)][:id]
      redirect_to(:size => params[:size], :invert => params[:invert], :c1 => params[:c1], :c2 => params[:c2], :c3 => params[:c3])
    end
    @stack = Stack.find(559, :include => [{:line => :genes}], :conditions => 'stacks.multibrain = true and public = true')
    if params[:c1] == nil || params[:c1] == '' || params[:c1] == 'nc82'
      @stack1 = @stack.clone()
      @stack1[:name] = '2226MaleDualA-nc82'
      @stack1.line[:name] = 'nc82'
      @stack1.line[:gene] = 'brp'
    else
      @stack1 = Stack.find(params[:c1], :include => [{:line => :genes}], :conditions => 'stacks.multibrain = true and public = true')
    end
    if params[:c2] == nil || params[:c2] == '' || params[:c2] == 'nc82'
      @stack2 = @stack.clone()
      @stack2[:name] = '2226MaleDualA-nc82'
      @stack2.line[:name] = 'nc82'
      @stack2.line[:gene] = 'brp'
    else
      @stack2 = Stack.find(params[:c2], :include => [{:line => :genes}], :conditions => 'stacks.multibrain = true and public = true')
    end
     if params[:c3] == nil || params[:c3] == '' || params[:c3] == 'nc82'
      @stack3 = @stack.clone()
      @stack3[:name] = '2226MaleDualA-nc82'
      @stack3.line[:name] = 'nc82'
      @stack3.line[:gene] = 'brp'
    else
      @stack3 = Stack.find(params[:c3], :include => [{:line => :genes}], :conditions => 'stacks.multibrain = true and public = true')
    end
    
    @channelMap = [['Merged', 'merge'],
      [@stack1.line[:gene] == nil ? @stack1.line[:name] : @stack1.line[:gene], @stack1[:name]],
      [@stack2.line[:gene] == nil ? @stack2.line[:name] : @stack2.line[:gene], @stack2[:name]],
      [@stack3.line[:gene] == nil ? @stack3.line[:name] : @stack3.line[:gene], @stack3[:name]]]
    @img_dir = url_for :controller => 'images', :only_path => true, :trailing_slash => true
    case params[:size]
    when 'full'
      @size = 'full'
      @jumpMult = (@stack.max_res_x / 512.0).to_s
    when '768'
      @size = '768'
      @jumpMult = '1.5'
    else
      @size = '512'
      @jumpMult = '1.0'
    end
  end

  def new
    redirect_to :controller => "welcome" unless logged_in?
    @stack = Stack.new
  end

  def autonew
    redirect_to :controller => "welcome" unless logged_in?
    @line_list = Line.find(:all).collect{|l| [l.name, l.id] }.sort
    @stacks = Stack.find(:all)
    @file_list = Dir.glob(AUTO_STACK_FOLDER + '*.lsm')
    @file_list.map! do |filename|
      File.basename(filename).gsub('.lsm','')
    end
    @file_list_zero = @file_list.clone
    @stacks.each do |stack|
      @file_list.delete(stack.name)
    end
    @file_list.each do |file|
      #sanity check - remove strange matches
      if ! FileTest.file?(AUTO_STACK_FOLDER + file + '.lsm')
        @file_list.delete(file)
      end
    end
    # Find a matching line for the first folder name
    @folder_num = /[0-9]+/.match(@file_list[0])
    if @folder_num != nil
      folder_fill = @folder_num.to_s().rjust(6, '0')
      linematch = Line.find(:first,
        :conditions => "name ilike '%#{folder_fill}'",
        :order => 'name')
      if linematch != nil
        @stack = Stack.new
        @stack.line_id = linematch.id
      else
        #New line required
        @line_list.insert(0, ["-- CPTI-#{folder_fill} (create new) --", 0])
      end
    end
  end
  
  def autocreate
    
    redirect_to :controller => "welcome" unless logged_in?

    @line_id = params[:stack][:line_id]
    
    if (@line_id == '0')
      #We need to create this line first
      stack_num = /[0-9]+/.match(params[:stack][:name])
      @line = Line.new(:name => "CPTI-#{stack_num.to_s().rjust(6, '0')}", :comments => '', :gene => nil)
      if @line.save
        @line_id = @line.id
      else
        #Error - could not create new line
        flash[:notice] = "Could not create line."
        render :action => 'autonew'
      end
    end
    
    @filename = AUTO_STACK_FOLDER + params[:stack][:name] + '.lsm'
    #sanity check
    if FileTest.file?(@filename)
      exe_path = 'C:/dev/BioImageConvert/imgcnv/imgcnv.exe'
      command = "#{exe_path} -i \"#{@filename}\" -info"
      exec_result = %x[#{command}]

      match = exec_result.match(/.*zsize: (\d+).*/m)
      @zn = match[1].to_i unless match == nil
      match = exec_result.match(/.*channels: (\d+).*/m)
      @channels = match[1].to_i unless match == nil
      match = exec_result.match(/.*width: (\d+).*/m)
      @width = match[1].to_i unless match == nil
      match = exec_result.match(/.*height: (\d+).*/m)
      @height = match[1].to_i unless match == nil

      @stack = Stack.new(:name => params[:stack][:name], :num_images => @zn, \
          :has_med_res => true, :has_hi_res => true, \
          :max_res_x => @width, :max_res_y => @height, :comments => '', \
          :line_id => @line_id, :dateadded => Time.now, :num_channels => @channels)

      #TODO: start extractor thread???
      
    end

    if @stack.save
      flash[:notice] = "Stack was successfully auto created. (<a href=\"show/#{@stack.id}\">#{@stack.name}</a>)"
      redirect_to :action => 'autonew'
    else
      flash[:notice] = "Could not create stack."
      render :action => 'autonew'
    end
    
  end

  def create
    redirect_to :controller => "welcome" unless logged_in?
    @stack = Stack.new(params[:stack])
    if @stack.save
      flash[:notice] = 'Stack was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    redirect_to :controller => "welcome" unless logged_in?
    @stack = Stack.find(params[:id])
  end

  def update
    redirect_to :controller => "welcome" unless logged_in?
    @stack = Stack.find(params[:id])
    if @stack.update_attributes(params[:stack])
      flash[:notice] = 'Stack was successfully updated.'
      redirect_to :action => 'show', :id => @stack
    else
      render :action => 'edit'
    end
  end

  def destroy
    redirect_to :controller => "welcome" unless logged_in?
    Stack.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
end
