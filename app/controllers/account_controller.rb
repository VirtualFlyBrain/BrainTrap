class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  # before_filter :login_from_cookie

  require 'BrainOntologyCache'

  # say something nice, you goof!  something sweet.
  def index
    if !logged_in?
      redirect_to(:action => 'login') # unless logged_in? || User.count > 0
    end
  end
  
  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => 'account', :action => 'index')
      flash[:notice] = "Logged in successfully"
    end
  end
  
  def signup
    #Signup Disabled
    #    @user = User.new(params[:user])
    #    return unless request.post?
    #    @user.save!
    #    self.current_user = @user
    #    redirect_back_or_default(:controller => 'account', :action => 'index')
    #    flash[:notice] = "Thanks for signing up!"
    #  rescue ActiveRecord::RecordInvalid
    #    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'login')
  end
  
  def migrate_ontology
    if !logged_in? || !current_user.admin
      redirect_to :action => 'login'
    else
      @tag_count = 0
      @result_text = ''
      #check every tag
      all_tags = Tag.find(:all)
      for tag in all_tags do
        
        @tag_count += 1
        
        tag_text = tag[:tag].clone()
        
        #New names for same structures
        tag_text.gsub!('[brain]', '[adult brain]');
        tag_text.gsub!('[cerebral cortex]', '[adult brain cortex]');
        tag_text.gsub!('[central body complex]', '[adult central complex]');
        tag_text.gsub!('[optic neuropil]', '[optic lobe]');
        tag_text.gsub!('[antennal lobe]', '[adult antennal lobe]');
        tag_text.gsub!('[antennal glomerulus]', '[adult antennal lobe glomerulus]');
        tag_text.gsub!('[mushroom body]', '[adult mushroom body]');
        tag_text.gsub!('[heel of mushroom body]', '[mushroom body spur]');
        tag_text.gsub!('[alpha-lobe]', '[mushroom body alpha-lobe]');
        tag_text.gsub!('[alpha\'-lobe]', '[mushroom body alpha\'-lobe]');
        tag_text.gsub!('[beta-lobe]', '[mushroom body beta-lobe]');
        tag_text.gsub!('[beta\'-lobe]', '[mushroom body beta\'-lobe]');
        tag_text.gsub!('[gamma-lobe]', '[mushroom body gamma-lobe]');
        tag_text.gsub!('[gamma\'-lobe]', '[mushroom body gamma\'-lobe]');
        tag_text.gsub!('[stalk of mushroom body]', '[adult pedunculus]');
        tag_text.gsub!('[calyx of mushroom body]', '[calyx of adult mushroom body]');
        tag_text.gsub!('[subesophageal ganglion]', '[adult subesophageal ganglion]');
        tag_text.gsub!('[deutocerebrum]', '[adult deuterocerebrum]');
        tag_text.gsub!('[protocerebrum]', '[adult protocerebrum]');
        tag_text.gsub!('[tritocerebrum]', '[adult tritocerebrum]');
        tag_text.gsub!('[horizontal fiber system]', '[horizontal fiber system neuron]');
        tag_text.gsub!('[lateral triangle]', '[bulb]');
        
        #new terms in the ontology
        if tag_text == 'lateral horn'
          tag_text = '[lateral horn]'
        end
        if tag_text == 'superior arch'
          tag_text = '[superior arch commissure]'
        end
        #tag_text.gsub!('lateral horn', '[lateral horn]');
        #tag_text.gsub!('superior arch', '[superior arch commissure]');
        
        #terms no longer part of adult brain
        tag_text.gsub!('[ocellar nerve]', 'ocellar nerve');
        tag_text.gsub!('[Kenyon cell]', 'Kenyon cell');
        
        #Clarify these regions
        if tag_text == 'all neuropil' || tag_text == 'expression in all neuropil areas'
          tag_text = 'all neuropil ( [supraesophageal ganglion], [adult subesophageal ganglion] )'
        end
        if tag_text == 'unstructured neuropil'
          tag_text = 'unstructured neuropil ( [optic lobe], [adult subesophageal ganglion], [adult deuterocerebrum], [adult protocerebrum] )'
        end
        
        if tag_text == tag[:tag]
          @result_text += "#{tag[:tag]} : No change.<br/>\n"
        else
          @result_text += "#{tag[:tag]} > #{tag_text}.<br/>\n"
        end
        
        if tag.update_attributes(:tag => tag_text)
          @result_text += " --- tag updated OK<br/>\n"
          ontology_terms = tag.tag.scan(/\[([^\]]*)\]/)
          conn = ActiveRecord::Base.connection();
          conn.execute "delete from tag_term where tag_id = #{tag[:id]}"
          ontology_terms.each do |term|
            fid = BrainOntologyCache.instance.term_to_fid(term[0])
            #puts "adding term #{fid} for tag #{tag[:id]}"
            conn.execute "insert into tag_term (tag_id, term_id) values (#{tag[:id]}, '#{fid}')"
            @result_text += " --- linked to term : [#{term}] = #{fid}<br/>\n"
          end
        else
          @result_text += " --- ERROR updating tag<br/>\n"
        end
        
      end
    end
  end
  
  def refresh_obo
    if !logged_in?
      redirect_to :action => 'login'
    else
      
      obo_filename = "C:/dev/BrainTrap/script/fly_anatomy.obo"
      
      conn = ActiveRecord::Base.connection();
      
      puts 'Marking current data as obsolete.'
      
      conn.execute 'select update_ontology()'
      
      #id_to_term = Hash.new
      #name_to_term = Hash.new
      
      current_term = nil    
      
      puts'Reading OBO file.'
      
      id_to_term = Hash.new
      name_to_term = Hash.new
      
      added_terms = 0
      added_synonyms = 0
      
      open( obo_filename ) do |f|
        
        f.each do |line|
          #puts line
          line.strip!
          
          if line =~ /^\[Term\]/
            
            #Continue with next term
            current_term = Term.new
            #puts 'got a term'
            
          elsif line =~ /^\s*$/
            
            #puts 'got a string'
            next unless current_term
            
            # This term is complete - complete term processing
            #id_to_term[current_term.id] = current_term
            #name_to_term[current_term.name] = current_term
            
            id_to_term[current_term.id] = current_term
            name_to_term[current_term.name] = current_term
            
            added_terms += 1
            added_synonyms += current_term.synonyms.length
            
            current_term = nil
            
          elsif line =~ /^([\w\-]+): \s*(.*\S)\s*/
            
            #puts 'got a colon'
            key = $1.dup
            value = $2.dup
            
            next unless current_term
            
            case key
              when 'id'
              current_term.id = sqlescape(value)
              when 'name'
              current_term.name = sqlescape(value)
              when 'subset'
              current_term.subset = sqlescape(value)
              when 'def'
              if value =~ /"(.*)" \s*\[(.*)\]\s*/
                current_term.definition = sqlescape($1)
              else
                puts "non-matching def #{value}."
              end
              when 'synonym', 'related_synonym', 'exact_synonym', 'broad_synonym', 'narrow_synonym'
              if value =~ /"(.*)"([^\[]*)\[(.*)\]\s*/
                current_term.synonyms.push sqlescape($1)
              else
                puts "no regex match for synonym"
              end        
              when 'is_a'
              if value =~ /([a-zA-Z:0-9]+) \! (.*)/
                current_term.is_a.push sqlescape($1)
              end
              when 'relationship'
              if value =~ /^([\w\-_]+) ([a-zA-Z:0-9]+) \! (.*)/
                relationship_type = $1.dup
                other_id = $2.dup
                # This is either develops_from or part_of:
                case relationship_type            
                  when 'develops_from'
                  current_term.develops_from.push sqlescape(other_id)
                  when 'part_of'
                  current_term.part_of.push sqlescape(other_id)
                end
              else
                puts "broken parsing of relationship: '#{value}'"
              end
              
            end
            
          end
          
        end
        
        puts 'Read OBO file.'
        puts 'Linking nodes.'
        
        #link each node to its children (part_of and is_a relations only)
        id_to_term.each_value do |term|
          term.is_a.each do |parent|
            if id_to_term[parent] != nil
              id_to_term[parent].children.push(term)
            end
          end
          term.part_of.each do |parent|
            if id_to_term[parent] != nil
              id_to_term[parent].children.push(term)
            end
          end
        end
        
        puts 'Labeling brain nodes.'
        
        #Find and label brain parts
        brain_term = name_to_term['adult brain']
        label_brain_part(brain_term)
        
        puts 'Persisting to database.'
        
        id_to_term.each_value do |term|
          if term.part_of_brain
            puts term.name
            term.persist_to(conn)
          end
        end
        
      end
      
      @summary = "Added #{added_terms} terms and #{added_synonyms} synonyms!"
    end
  end
  
  protected
  
  def sqlescape (sqlstring)
    escaped = sqlstring
    escaped = escaped.gsub(/\\n/, '')
    escaped = escaped.gsub(/\\"/, '"')
    escaped = escaped.gsub(/'/, '\'\'')
    escaped = escaped.gsub(/\\/, '\\\\\\\\')
    return escaped
  end
  
  def label_brain_part (term)
    #puts "labelling #{term.name}"
    term.part_of_brain = true
    term.children.each do |child|
      label_brain_part(child)
    end
  end
  
  class Term
    
    attr_accessor :id, :name, :subset, :definition, :synonyms, :develops_from, :part_of, :is_a, :children, :part_of_brain
    
    def initialize
      @synonyms = Array.new
      @develops_from = Array.new
      @part_of = Array.new
      @is_a = Array.new
      @children = Array.new
      @part_of_brain = false
    end
    
    def persist_to( conn )
      
      #puts "Adding term '#{name}'."
      
      #puts 'EXECUTING:select add_term' + \
      #"('#{id}', '#{name}', #{subset==nil ? 'NULL' : '\'' + subset + '\''}," + \
      #" #{definition==nil ? 'NULL' :  '\'' + definition + '\''}, #{part_of_brain})"
      
      conn.execute("select add_term('#{id}', '#{name}', #{subset==nil ? 'NULL' : '\'' + subset + '\''}," + \
    " #{definition==nil ? 'NULL' :  '\'' + definition + '\''}, #{part_of_brain})")
      
      @synonyms.each do |synonym|
        conn.execute("select add_synonym('#{id}', '#{synonym}')")
      end
      
      @develops_from.each do |df_id|
        conn.execute("select add_develops_from('#{id}', '#{df_id}')")
      end
      
      @part_of.each do |po_id|
        conn.execute("select add_part_of('#{id}', '#{po_id}')")
      end
      
      @is_a.each do |ia_id|
        conn.execute("select add_is_a('#{id}', '#{ia_id}')")
      end
    end
    
  end
  
end
