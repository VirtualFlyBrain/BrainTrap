# TreeNode.rb
# 20 June 2007
#

# Contains information about one node of the ontology tree
class TreeNode

  attr_accessor :id, :name, :type, :tag_count, :children

  def initialize
    @id = ''
    @name = ''
    @type = ''
    @tag_count = 0
    @children = nil
    
  end
  
end


