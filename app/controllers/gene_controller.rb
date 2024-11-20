class GeneController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    @genes = Gene.find_by_sql('select genes.*, count(genes_lines.line_id) as line_count from genes, genes_lines, lines where genes.id = genes_lines.gene_id and genes_lines.line_id = lines.id and lines.public group by genes.id, genes.gene, genes.geneid, genes.genefbgn order by genes.gene')
  end
  
  def gene_lines
    @lines = Line.find(:all, :conditions => { :geneid => params[:geneid], :public => true})
  end
  
  def gene_stacks
    @stacks = Stack.find( :all, :include => :line, :conditions => ['lines.geneid = ? and lines.public = true and stacks.public = true', params[:geneid]] )
  end
  
  def autolink
    #Link lines with gene names and CG numbers to the genes table
    redirect_to :controller => "welcome" unless logged_in?
    
    @message = ''

    if params[:commit] == 'Auto Link'
      @message += 'Executing: <br/>'
      @exec = true
    end
    
    @lines = Line.find_by_sql('select lines.* from lines left join genes_lines on lines.id = genes_lines.line_id where genes_lines.line_id is null order by lines.id')
    @lines.each do |l|
      @message += "Line #{l.name}:<br/>"
      geneids = l.geneid.split(' / ');
      genenames = l.gene.split(' / ');
      if geneids.length != genenames.length
        @message += "Warning: #{geneids.length} gene ids does not match #{genenames.lenght} names.<br/>"
        next
      end
      for gix in (0..geneids.length-1) do
        gi = geneids[gix]
        gn = genenames[gix]
        @genes = Gene.find(:all, :conditions => { :geneid => gi })
        if @genes.length > 1
          @message += "  Warning: unmatched gene #{gi} mathces more than one gene (#{@genes.collect{|g| g.gene}.join(' ')}).<br/>"
        elsif @genes.length == 1
          @message += "  Matching #{gi} with existing gene #{@genes[0].geneid}.<br/>"
          if @exec
            l.genes.push(@genes[0])
            if l.save
              @message += 'OK<br/>'
            else
              @message += 'Error linking new gene'
              render :action => 'autolist'
            end
          end
        else
          @message += "  No match - adding new gene #{gi}.<br/>"
          if @exec
            @newgene = Gene.new(:gene => gn, :geneid => gi, :genefbgn => '')
            if @newgene.save
              l.genes.push(@newgene)
              if l.save
                @message += 'OK<br/>'
              else
                @message += 'Error linking new gene'
                render :action => 'autolist'
              end
            else
              @message += 'Error creating new gene.'
              render :action => 'autolist'
            end
          end
        end
      end
    end
    
  end
  
  def compare
    @genes = Gene.find(params[:compare_id])
    conn = ActiveRecord::Base.connection();
    @tagged = {};
    
    for gene in @genes do
      ganat = conn.execute "select term.name from term
      where term.id in
      (select tag_term.term_id from tag_term
      where tag_term.tag_id in
      (select tags.id from tags
      where tags.stack_id in
      (select stacks.id from stacks
      where stacks.line_id in
      (select line_id from genes_lines
      where gene_id = #{gene.id}))))";
      for ga in ganat do
        if DATA_ACCESS_HASH
          name = ga['name'];
        else
          name = [ga[0]];
        end
        if !@tagged.key?(name)
          @tagged[name] = {};
        end
        @tagged[name][gene.gene] = true;
      end
    end
    @anatomy = @tagged.keys.sort;
  end
end
