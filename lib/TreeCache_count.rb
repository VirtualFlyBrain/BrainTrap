# TreeCache.rb
# 20 June 2007
#

require 'singleton'
#require 'postgres'

require 'TreeCache'

# TreeCache is a singleton object to contain a brain ontology tree structure in memory
class TreeCacheCount
  include Singleton

  def initialize

    conn = ActiveRecord::Base.connection();
    
    res = conn.execute('select id, name, count(tag_term.term_id) as tag_count from term left join tag_term ' + \
      'on term.id = tag_term.term_id where name = \'adult brain\' and is_current = true ' + \
      'group by term.id, term.name')
    
    @brain_node = TreeNode.new
    if DATA_ACCESS_HASH
      @brain_node.id = res[0]['id']
      @brain_node.name = res[0]['name']
      @brain_node.tag_count = res[0]['tag_count']
    else
      @brain_node.id = res[0][0]
      @brain_node.name = res[0][1]
      @brain_node.tag_count = res[0][2]
    end
    
    @parent_hash = Hash.new
    
    setAllChildren(@brain_node, conn)
    
  end
  
  def setAllChildren(current_node, conn)
    children = nil
    
    # Get is_a and part_of children
    res = conn.execute('select id, name, \'is_a\' as type, count(tag_term.term_id) as tag_count ' + \
        'from term left join tag_term on term.id = tag_term.term_id, is_a ' + \
        'where is_a.term_id = term.id ' + \
        "and is_a.is_a_term_id = '#{current_node.id}' and " + \
        'is_a.is_current = true and term.is_current = true ' + \
        'group by term.id, term.name ' + \
        'union ' + \
        'select id, name, \'part_of\' as type, count(tag_term.term_id) as tag_count ' + \
        'from term left join tag_term on term.id = tag_term.term_id, part_of ' + \
        'where part_of.term_id = term.id ' + \
        "and part_of.part_of_term_id = '#{current_node.id}' and " + \
        'part_of.is_current = true and term.is_current = true ' + \
        'group by term.id, term.name ' + \
        'order by name')
    if (DATA_ACCESS_HASH && res.ntuples > 0) || (!DATA_ACCESS_HASH && res.num_tuples > 0)
      children = Array.new unless children != nil
      res.each do |r|
        child = TreeNode.new
        if DATA_ACCESS_HASH
          child.id = r['id']
          child.name = r['name']
          child.type = r['type']
          child.tag_count = r['tag_count']
        else
          child.id = r[0]
          child.name = r[1]
          child.type = r[2]
          child.tag_count = r[3]
        end
        setAllChildren(child, conn)
        children.push(child)
        #Add to parent list hash
        @parent_hash[child.id] = Array.new unless @parent_hash[child.id] != nil
        @parent_hash[child.id].push(current_node.id)
      end
    end
   
    current_node.children = children
  end
  
  def getBrainNode()
    return @brain_node
  end
  
  def getParentHash()
    return @parent_hash
  end

end
