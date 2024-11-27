# search_controller.rb
# 15 June 2007
#
require 'BrainOntologyCache'
require 'TreeCache'
require 'TreeNode'

include ActionView::Helpers::UrlHelper;

class SearchController < ApplicationController

  @tree_html = ''

  def index
    search_form
  end
  
  def ontology_match
    prefix = ''
    max = 100
    format = 'json'

    if params['prefix'] != nil
      prefix = params['prefix']
    end
    
    if params['max'] != nil
      begin
        max = Integer(params['max'])
      rescue
        max = 100
      end
    end

    if params['ontology'] != nil && params['ontology'].casecmp('full') == 0
      matches = OntologyCache.instance.get_matches(prefix, max)
    else
      matches = BrainOntologyCache.instance.get_matches(prefix, max)
    end

    case params['format']
    when 'xml'
      xout = ''
      xml = Builder::XmlMarkup.new(:target => xout)
      # make sure not to send html but text/xml
      headers["Content-Type"] = "text/xml; charset=utf-8"
      xml.instruct! :xml, :version=>"1.0"
      xml.matches{
        if matches != nil
          matches.each do |match|
            xml.match do
              xml.name(match[0])
              xml.obo_id(match[1])
              if match.length > 2
                xml.synonym(match[2])
              end
            end
          end
        end
      }
      render :plain => xout
    else
      # Default output is json format
      # make sure not to send html but text/plain
      headers["Content-Type"] = "text/plain; charset=utf-8" 
      render :plain => matches.to_json
    end
  end
    
  def get_tree
    
    brain_node = TreeCache.instance.getBrainNode()
    
    case params['format']
    when 'xml'
      xout = ''
      xml = Builder::XmlMarkup.new(:target => xout)
      # make sure not to send html but text/xml
      headers["Content-Type"] = "text/xml; charset=utf-8"
      xml.instruct! :xml, :version=>"1.0"
      xml.tree{
        recurse_tree_xml(brain_node, xml)
      }
      render :plain => xout
    else
      # Default output is json format
      # make sure not to send html but text/plain

      headers["Content-Type"] = "text/plain; charset=utf-8" 
      render :plain => brain_node.to_json
    end

  end
  
  def search_form

    if !@node_count
      
      #TODO: find a better way to get this image url
      @img_dir = "/images/"
      @search_dir = url_for :controller => 'search', :only_path => true, :trailing_slash => true
      @search_dir = @search_dir.gsub('index/', '')

      treeData = TreeCache.instance.getTreeData();
      if treeData != nil
        @string_to_fid = treeData[0];
        @fid_to_nodes = treeData[1];
        @node_parents = treeData[2];
        @collapse_nodes = treeData[3];
        @all_nodes = treeData[4];
        @tree_html = treeData[5];
      else
        @node_count = 1;
        @string_to_fid = Hash.new;
        @fid_to_nodes = Hash.new;
        @node_parents = Hash.new;
        @collapse_nodes = Array.new;
        @all_nodes = Array.new;
        @tree_html = "<ul class='treenodetop'>\n"
        recurse_tree_html(TreeCache.instance.getBrainNode(), 0, Array.new)
        @tree_html += "</ul>\n"
        TreeCache.instance.setTreeData([@string_to_fid, @fid_to_nodes, @node_parents, @collapse_nodes, @all_nodes, @tree_html]);        
      end
      
    end

  end
  
  def search_form_gene
    search_form()
  end
  
  def search_form_free
    
  end
  
  def search_results
    stacks_order = "dateadded desc, name"
    if params[:mode] == 'freetext'
      if params[:quick_search] && params[:quick_search].length > 0
        search_terms = params[:quick_search].scan(/[A-Za-z0-9]+/)

        if search_terms.length == 0
          flash[:notice] = "Search term contains invaild characters - letters and numbers only please"
          redirect_to :action => 'index'
          return
        end
      
        like_sql = search_terms.collect { |term|
          "(tags.tag ILIKE '%#{term}%' OR lines.name ILIKE '%#{term}%' OR genes.gene ILIKE '%#{term}%' OR genes.geneid ILIKE '%#{term}%')"
        }.join(params[:match] == 'any' ? ' OR ' : ' AND ')
      
        search_sql = "select distinct stacks.* from stacks, tags, lines, genes_lines, genes " +
          "where stacks.id = tags.stack_id and tags.active = true and " +
          "stacks.line_id = lines.id and lines.id = genes_lines.line_id and " +
          "genes_lines.gene_id = genes.id and (#{like_sql}) " +
          "and stacks.public = true and lines.public = true " +
          "order by #{stacks_order}"

        @search_list = "Searching for: #{search_terms.join(' ')}"
        @stack_pages = nil
        @stacks = Stack.find_by_sql search_sql
      else
        flash[:notice] = "Please enter a search term"
        redirect_to :action => 'index'
      end
    elsif params[:searchfid]
      @search_list = 'Searching for:'
      @sql_list = ''
      
      base_search_fids = Array.new(params[:searchfid])
      subcomponents = Array.new
      supercomponents = Array.new
      
      if params[:subcomponents] != nil
        bn = TreeCache.instance.getBrainNode()
        get_subcomponents(bn, base_search_fids, subcomponents, false)
      end
      
      if params[:supercomponents] != nil
        ph = TreeCache.instance.getParentHash()
        get_supercomponents(ph, base_search_fids, supercomponents)
      end
      
      all_search_fids = base_search_fids + subcomponents + supercomponents

      @search_fid_terms = params[:searchfid].map{|fid| OntologyCache.instance.fid_to_term(fid)}
      @search_list += '<br/>' + @search_fid_terms.join("<br/>")
      if params[:subcomponents]
        @search_list += "<br/>(and all subcomponents)\n"
      end
      if params[:supercomponents]
        @search_list += "<br/>(and all supercomponents)\n"
      end
      
      all_search_fids.each do |fid|
        term = OntologyCache.instance.fid_to_term(fid)
        @sql_list += "," unless @sql_list == ''
        @sql_list += "'#{fid}'"
      end
      
      search_sql = "select distinct stacks.* from stacks, tags, tag_term, lines " +
        "where stacks.id = tags.stack_id and tags.id = tag_term.tag_id " +
        "and stacks.line_id = lines.id " +
        "and tags.active = true and tag_term.term_id in (#{@sql_list}) " +
        "and stacks.public = true and lines.public = true " +
        "order by #{stacks_order}"
        
      #@stack_pages, @stacks = paginate_by_sql( Stack, search_sql, 10 )
      @stack_pages = nil
      @stacks = Stack.find_by_sql search_sql 
      
    else
      flash[:notice] = "Nothing to search for - please select some brain areas"
      #redirect_to :action => 'index'
    end

end

def interaction_search
  conn = ActiveRecord::Base.connection()
  @message = ''
  suspectcount = 0
  
  filename = 'C:\dev\BrainTrap\CPTI-DroIDinteractions.csv'
  file = File.new(filename, 'r')
  file.each_line("\n") do |row|
    col = row.split(",")
    gene1 = col[0]
    gene2 = col[1]
    
    basefids = Array.new
    subcomponents = Array.new
    supercomponents = Array.new
  
    res = conn.execute("select distinct tags.id from genes, genes_lines, lines, stacks, tags, tag_term " +
      "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
      "and stacks.id = tags.stack_id and tags.id is not null " +
      "and genes.gene like '#{gene1}'")
      
    gene1tags = 0
    if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
      res.each do |r|
        gene1tags += 1
      end
    end
  
    # get regions tagged for gene1
    res = conn.execute("select distinct tag_term.term_id from genes, genes_lines, lines, stacks, tags, tag_term " +
      "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
      "and stacks.id = tags.stack_id and tag_term.tag_id = tags.id " +
      "and genes.gene like '#{gene1}'")
      
    if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
      res.each do |r|
        if DATA_ACCESS_HASH
          basefids.push(r['term_id'])
        else
          basefids.push(r[0])
        end
      end
    end
    
    #get sub- and super- components for gene1    
    bn = TreeCache.instance.getBrainNode()
    get_subcomponents(bn, basefids, subcomponents, false)
    ph = TreeCache.instance.getParentHash()
    get_supercomponents(ph, basefids, supercomponents)
    
    all_gene1_fids = basefids + subcomponents + supercomponents
    
    res = conn.execute("select distinct tags.id from genes, genes_lines, lines, stacks, tags, tag_term " +
      "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
      "and stacks.id = tags.stack_id and tags.id is not null " +
      "and genes.gene like '#{gene2}'")
      
    gene2tags = 0
    if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
      res.each do |r|
        gene2tags += 1
      end
    end

    res = conn.execute("select distinct tag_term.term_id from genes, genes_lines, lines, stacks, tags, tag_term " +
      "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
      "and stacks.id = tags.stack_id and tag_term.tag_id = tags.id " +
      "and genes.gene like '#{gene2}'")
  
    basefids = Array.new
    
    if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
      res.each do |r|
        if DATA_ACCESS_HASH
          basefids.push(r['term_id'])
        else
          basefids.push(r[0])
        end
      end
    end
    
    match = 0
    
    basefids.each do |bf|
      if all_gene1_fids.include?(bf)
        match = match + 1
      end
    end
    
    if match == 0 && gene1tags > 0 && gene2tags > 0
      @message += "#{match} region matches for interaction #{gene1} -- #{gene2}<br/>\n"
      suspectcount += 1
    end
        
  end
  
  @message += "<br/><br/><b>#{suspectcount} total suspects</b><br/>"

end

def interaction_search2
  conn = ActiveRecord::Base.connection()
  @message = ''
  suspectcount = 0
  
  resinter = conn.execute("select g1.id g1id, g1.gene g1symbol, g2.id g2id, g2.gene g2symbol " +
    "from genes g1 left join droid_correlation_2011_02 on (g1.genefbgn = fly_gene1) " +
    "left join genes g2 on (g2.genefbgn = fly_gene2) " +
    "where g2.id is not null order by g1.gene, g2.gene");
    
  if (DATA_ACCESS_HASH && resinter.ntuples > 0) || (!DATA_ACCESS_HASH && resinter.num_tuples > 0)
    resinter.each do |inter|
      if DATA_ACCESS_HASH
        gene1 = inter['g1id']
        gene1s = inter['g1symbol']
        gene2 = inter['g2id']
        gene2s = inter['g2symbol']
      else
        gene1 = inter[0]
        gene1s = inter[1]
        gene2 = inter[2]
        gene2s = inter[3]
      end
      
      basefids = Array.new
      subcomponents = Array.new
      supercomponents = Array.new
    
      res = conn.execute("select distinct tags.id from genes, genes_lines, lines, stacks, tags, tag_term " +
        "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
        "and stacks.id = tags.stack_id and tags.id is not null " +
        "and genes.id = #{gene1}")
        
      gene1tags = 0
      if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
        res.each do |r|
          gene1tags += 1
        end
      end
    
      # get regions tagged for gene1
      res = conn.execute("select distinct tag_term.term_id from genes, genes_lines, lines, stacks, tags, tag_term " +
        "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
        "and stacks.id = tags.stack_id and tag_term.tag_id = tags.id " +
        "and genes.id = #{gene1}")
        
      if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
        res.each do |r|
          if DATA_ACCESS_HASH
            basefids.push(r['term_id'])
          else
            basefids.push(r[0])
          end
        end
      end
      
      #get sub- and super- components for gene1    
      bn = TreeCache.instance.getBrainNode()
      get_subcomponents(bn, basefids, subcomponents, false)
      ph = TreeCache.instance.getParentHash()
      get_supercomponents(ph, basefids, supercomponents)
      
      all_gene1_fids = basefids + subcomponents + supercomponents
      
      res = conn.execute("select distinct tags.id from genes, genes_lines, lines, stacks, tags, tag_term " +
        "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
        "and stacks.id = tags.stack_id and tags.id is not null " +
        "and genes.id = #{gene2}")
        
      gene2tags = 0
      if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
        res.each do |r|
          gene2tags += 1
        end
      end
  
      res = conn.execute("select distinct tag_term.term_id from genes, genes_lines, lines, stacks, tags, tag_term " +
        "where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.id = stacks.line_id " +
        "and stacks.id = tags.stack_id and tag_term.tag_id = tags.id " +
        "and genes.id = #{gene2}")
    
      basefids = Array.new
      
      if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
        res.each do |r|
          if DATA_ACCESS_HASH
            basefids.push(r['term_id'])
          else
            basefids.push(r[0])
          end
        end
      end
      
      match = 0
      
      basefids.each do |bf|
        if all_gene1_fids.include?(bf)
          match = match + 1
        end
      end
      
      if match == 0 && gene1tags > 0 && gene2tags > 0
        link1 = link_to(gene1s, :controller => 'stack', :action => 'list', :geneid => gene1)
        link2 = link_to(gene2s, :controller => 'stack', :action => 'list', :geneid => gene2)
        @message += "#{match} region matches for interaction #{link1} -- #{link2}<br/>\n"
        suspectcount += 1
      end
          
    end
  end
  
  @message += "<br/><br/><b>#{suspectcount} total suspects</b><br/>"

end
  
  private
  
  def get_subcomponents(node, fids, subc, matching)
    match = matching
    if match
      subc.push node.id
    else
      fids.each do |fid|
        if fid == node.id
          match = true
          break
        end
      end      
    end
    if node.children != nil
      node.children.each do |c|
        get_subcomponents(c, fids, subc, match)
      end      
    end
  end
  
  def get_supercomponents(parent_hash, fids, superc)
    fids.each do |fid|
      parents = parent_hash[fid]
      if parents != nil
        parents.each do |parent|
          superc.push parent
        end
        get_supercomponents(parent_hash, parents, superc)
        superc.uniq!
      end
    end
  end
  
  def recurse_tree_xml(node, xmlb)
    xmlb.node('id' => node.id, 'name' => node.name) do
      if node.children != nil
        node.children.each do |c|
          recurse_tree_xml(c, xmlb)
        end
      end
    end
  end
  
  def recurse_tree_html(node, level, parents)
    fid = node.id #.gsub(':', '_')
    nodeid = "n#{@node_count}"  # node.id no longer needed: _#{node.id}".gsub(':', '_')
    nodename = node.name.gsub('&', '&amp;').gsub('"', '&quot;').gsub("'", "&#39;")
    jnodename = node.name.gsub('"', '_').gsub('\\', '_')
    jsnodename = jnodename.gsub("'", "\\\\'")
    bulletstyle = 'is_a'
    if node.type == 'part_of'
      bulletstyle = 'part_of'
    end
    bullettitle = bulletstyle.gsub('_', ' ')
    @node_count += 1
    
    @all_nodes.push(nodeid)
    
    if level > 0 && node.children != nil
      #Tell the GUI to collapse this node
      @collapse_nodes.push(nodeid)
    end
    
    #Record the unique node ids for this fid
    if @fid_to_nodes[fid]
      @fid_to_nodes[fid].push(nodeid)
    else
      @fid_to_nodes[fid] = Array.new
      @fid_to_nodes[fid].push(nodeid)
    end
    
    #Record the string for this fid
    if !@string_to_fid[jnodename]
      @string_to_fid[jnodename] = fid
    end
    
    #Record the parents of this node
    @node_parents[nodeid] = parents
    
    if node.children != nil
      @tree_html += "<li class=\"treenode\" id=\"#{nodeid}_li\">\n"
      @tree_html += "<img class=\"arrow\" src=\"#{@img_dir}#{bulletstyle}6g.png\" alt=\"#{bullettitle}\" title=\"#{bullettitle}\" onclick=\"toggletree('#{nodeid}')\" />" unless level == 0
      @tree_html += "<img class=\"expand\" id=\"#{nodeid}_i\" src=\"#{@img_dir}minus.png\" onclick=\"toggletree('#{nodeid}')\" />"
      @tree_html += "<input type=\"checkbox\" id=\"#{nodeid}\" onclick=\"cbclick('#{nodeid}', '#{fid}', '#{jsnodename}')\" onfocus=\"cbfocus('#{nodeid}')\" onblur=\"cbblur('#{nodeid}')\">" + \
        "<span class=\"treetextparent\" id=\"#{nodeid}_span\" onclick=\"toggletree('#{nodeid}')\">#{nodename}</span>" + \
        "</input>\n\n<ul class=\"treenode\" id=\"#{nodeid}_children\">\n"
        
      node.children.each do |c|
        #Ignore all the antennal lobe projection neurons for the top level of the tree (they mess it up)
        if level == 0 && (
          (c.name.length > 37 && c.name.index('antennal lobe projection neuron') != nil) ||
          c.name.index('multiglomerular projection neuron') != nil)
        else
          recurse_tree_html(c, level+1, parents.clone().push(nodeid))          
        end
      end
      @tree_html += "</ul></li>\n\n"
    else
      @tree_html += "<li class=\"treenode\" id=\"#{nodeid}_li\">\n" + \
        "<img class=\"arrow_d\" src=\"#{@img_dir}#{bulletstyle}6g.png\" alt=\"#{bullettitle}\" title=\"#{bullettitle}\" />" + \
        "<img class=\"expand_d\" src=\"#{@img_dir}blankg.png\" />" + \
        "<input type=\"checkbox\" id=\"#{nodeid}\" onclick=\"cbclick('#{nodeid}', '#{fid}', '#{jsnodename}')\" onfocus=\"cbfocus('#{nodeid}')\" onblur=\"cbblur('#{nodeid}')\">" + \
        "<span class=\"treetext\" id=\"#{nodeid}_span\">#{nodename}</span></input></li>\n"
    end
  end
  
end


