# OntologyCache.rb
# 13 June 2007
#

require 'singleton'
#require 'postgres'

# OntologyCache is a singleton object to contain all ontology information in memory
class OntologyCache
  include Singleton

  def set_selects()
    @term_select = 'select id, name from term where is_current = true'
    @syn_select = 'select term_id, synonym from synonym, term ' + \
    'where term.id = synonym.term_id and term.is_current = true and synonym.is_current = true'  
  end
  
  # Load the ontology from the database
  def initialize
    
    @min_chars = 2
    
    @term_select = nil
    @syn_select = nil
    
    set_selects()
  
    conn = ActiveRecord::Base.connection;

    @id_to_term = Hash.new
    #@id_to_syn = Hash.new
    
    @term_list = Array.new
    @synonym_list = Array.new
    @term_parts_list = Array.new
    @syn_parts_list = Array.new
    
    res = conn.execute(@term_select)
    res.each do |r|
      if DATA_ACCESS_HASH
        r_id = r['id']
        r_name = r['name']
      else
        r_id = r[0]
        r_name = r[1]
      end
      @id_to_term[r_id] = [r_name,r_id]
      name = r_name.downcase
      @term_list.push([name, r_id])
      #puts "term:#{name}"
      while name =~ /(\S*) (.*)/
        name = $2
        @term_parts_list.push([name, r_id])
        #puts "termpart:#{name}"
      end
      
    end
    
    res = conn.execute(@syn_select)
    res.each do |r|
      if DATA_ACCESS_HASH
        r_id = r['term_id']
        r_name = r['synonym']
      else
        r_id = r[0]
        r_name = r[1]
      end
      #@id_to_syn[r['term_id']] = [r['synonym'],r['term_id']]
      name = r_name.downcase
      @synonym_list.push([name, r_id])
      #puts "syn:#{name}"
      while name =~ /(\S*) (.*)/
        name = $2
        @syn_parts_list.push([name, r_id, r_name])
        #puts "synpart:#{name}"
      end
    end
    
    #conn.close();
    
    @term_list.sort!{|a,b| a[0] <=> b[0]}
    @synonym_list.sort!{|a,b| a[0] <=> b[0]}
    @term_parts_list.sort!{|a,b| a[0] <=> b[0]}
    @syn_parts_list.sort!{|a,b| a[0] <=> b[0]}
    
  end
  
  def fid_to_term (fid)
    if @id_to_term[fid]
      return @id_to_term[fid][0]
    end
    return nil
  end
  
  def term_to_fid (term)
    min = 0
    max = @term_list.length - 1
    index = max / 2
    
    current_term = @term_list[index][0]
    comp = current_term.casecmp(term)
    while comp != 0 && min <= max
      #binary search
      if comp == 1
        max = index - 1
      else
        min = index + 1
      end
      index = ((min + max) / 2).floor
      #get the next candidate
      current_term = @term_list[index][0]
      comp = current_term.casecmp(term)
    end
 
    return nil unless comp == 0
    return @term_list[index][1]
  end
  
  def bsearch (prefix, ordered)
    len = prefix.length
    min = 0
    max = ordered.length - 1
    index = max / 2
    
    term_pre = ordered[index][0][0..len-1]
    comp = term_pre.casecmp(prefix)
    while comp != 0 && min <= max
      #puts "index=#{index}, term=#{ordered[index][0]}, term_pre=#{term_pre}, comp=#{comp}"
      #binary search
      if comp == 1
        max = index - 1
      else
        min = index + 1
      end
      index = ((min + max) / 2).floor
      #get the next candidate
      term_pre = ordered[index][0][0..len-1]
      comp = term_pre.casecmp(prefix)
    end
    
    return nil unless comp == 0
    
    #puts "Match found at index #{index} (#{ordered[index-1][0]}=#{ordered[index-1][0][0..len-1]})."
    first = index
    last = index
    while ordered[first-1][0][0..len-1].casecmp(prefix) == 0
      first -= 1
    end
    while ordered[last+1][0][0..len-1].casecmp(prefix) == 0
      last += 1
    end
    
    #puts "Returning items #{first} to #{last}."
    
    return ordered[first..last]
    
  end
  
  def get_matches (prefix, max)
    
    return nil unless prefix != nil
    return nil unless prefix.length >= @min_chars
    
    matches = 0;
    results_list = Array.new
    
    #puts "Searching for up to #{max} matches for '#{prefix}'."
    term_matches = bsearch(prefix, @term_list)
    if term_matches != nil
      matches += term_matches.length
      results_list.concat(term_matches.map {|item| @id_to_term[item[1]]}) unless term_matches == nil
      return results_list unless matches < max || max <= 0
    end
    
    term_parts_matches = bsearch(prefix, @term_parts_list)
    if term_parts_matches != nil
      matches += term_parts_matches.length
      results_list.concat(term_parts_matches.map {|item| @id_to_term[item[1]]}) unless term_parts_matches == nil
      return results_list unless matches < max || max <= 0
    end
 
    syn_matches = bsearch(prefix, @synonym_list)
    if syn_matches != nil
      matches += syn_matches.length
      results_list.concat(syn_matches.map {|item| @id_to_term[item[1]] + ["#{item[0]}"]}) unless syn_matches == nil
      return results_list unless matches < max || max <= 0
    end

    syn_parts_matches = bsearch(prefix, @syn_parts_list)
    if syn_parts_matches != nil
      matches += syn_parts_matches.length
      results_list.concat(syn_parts_matches.map {|item| @id_to_term[item[1]] + ["#{item[2]}"]}) unless syn_parts_matches == nil    
      return results_list unless matches < max || max <= 0
    end
    
    return results_list
    
  end

end
