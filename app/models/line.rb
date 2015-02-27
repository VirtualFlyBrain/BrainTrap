class Line < ActiveRecord::Base
  has_many :stacks
  has_and_belongs_to_many :genes
end
