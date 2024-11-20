
require 'TreeCache'
require 'TreeNode'

class WelcomeController < ApplicationController
  def index
    @highlights = Stack.where(highlight: 1.., public: true).joins(:line).where(lines: {public: true}).order(highlight: :desc, dateadded: :desc)
    @totalimages = Stack.count_by_sql "select count(*) from stacks, lines where stacks.line_id = lines.id and stacks.public = true and lines.public = true"
    @totallines = Line.count_by_sql "select count(*) from lines where lines.public = true"
  end

  def about
    
  end
  
  def protocol
    
  end
end
