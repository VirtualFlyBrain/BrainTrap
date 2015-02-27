class Stack < ActiveRecord::Base
  belongs_to :line
  has_many :tags
end
