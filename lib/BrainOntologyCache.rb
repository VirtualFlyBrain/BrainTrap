# BrainOntologyCache.rb
# 14 June 2007
#
require 'OntologyCache'

#BrainOntology cache is an Ontology cache with entries restricted to parts of the brain
class BrainOntologyCache < OntologyCache
  include Singleton
  def set_selects()
    @term_select = 'select id, name from term where is_current = true and is_brain_part = true'
    @syn_select = 'select term_id, synonym from synonym, term ' + \
    'where term.id = synonym.term_id and term.is_current = true and synonym.is_current = true ' +\
    'and term.is_brain_part = true'
  end
end


