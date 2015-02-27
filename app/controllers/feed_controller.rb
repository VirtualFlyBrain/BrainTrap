# feed_controller.rb
# 04 October 2007
#

class FeedController < ApplicationController
  def initialize
    
  end
  
  def index
    annotations_xml
  end
  
  def line_annotation_xml
    xout = ''
    xml = Builder::XmlMarkup.new(:target => xout)
    # make sure not to send html but text/xml
    headers["Content-Type"] = "text/xml; charset=utf-8"
    xml.instruct! :xml, :version=>"1.0"
    @line = Line.find(params[:id], :conditions => { :public => true })
      xml.line do
        xml.cpti(@line.name)
        xml.gene(@line.gene)
        xml.geneid(@line.geneid)
        @line.stacks.each do |stack|
          @tags = stack.tags.find(:all, :conditions => ['active = true'])
          if (@tags.length > 0)
            @tags.each do |tag|
              xml.tag do
                xml.text(tag.tag)
                conn = ActiveRecord::Base.connection();
                @ontology_terms = conn.execute "select tag_term.term_id as fid from tag_term where tag_term.tag_id = #{tag.id}"
                if  (DATA_ACCESS_HASH && @ontology_terms.length > 0) || (!DATA_ACCESS_HASH && @ontology_terms.num_tuples > 0)
                  xml.terms{
                    @ontology_terms.each do |fid|
                      if DATA_ACCESS_HASH
                        xml.fid(fid['fid'])
                      else
                        xml.fid(fid[0])
                      end
                    end                        
                  }
                end
              end
            end
          end
        end
      end
    render :text => xout
  end
  
  def annotations_xml
    xout = ''
    xml = Builder::XmlMarkup.new(:target => xout)
    # make sure not to send html but text/xml
    headers["Content-Type"] = "text/xml; charset=utf-8"
    xml.instruct! :xml, :version=>"1.0"
    @lines = Line.find(:all, :order => 'id', :conditions => { :public => true })
    xml.lines {
      @lines.each do |line|
        xml.line do
          xml.cpti(line.name)
          xml.gene(line.gene)
          xml.geneid(line.geneid)
          xml.btlink("http://fruitfly.inf.ed.ac.uk/braintrap/line/show/#{line.id}")
          line.stacks.each do |stack|
            @tags = stack.tags.find(:all, :conditions => ['active = true'])
            if (@tags.length > 0)
              @tags.each do |tag|
                xml.tag do
                  xml.text(tag.tag)
                  conn = ActiveRecord::Base.connection();
                  @ontology_terms = conn.execute "select tag_term.term_id as fid from tag_term where tag_term.tag_id = #{tag.id}"
                  if  (DATA_ACCESS_HASH && @ontology_terms.length > 0) || (!DATA_ACCESS_HASH && @ontology_terms.num_tuples > 0)
                    xml.terms{
                      @ontology_terms.each do |fid|
                        if DATA_ACCESS_HASH
                          xml.fid(fid['fid'])
                        else
                          xml.fid(fid[0])
                        end
                      end                        
                    }
                  end
                end
              end
            end
          end
        end
      end
    }
    render :text => xout
  end
  
  def full_xml
    xout = ''
    xml = Builder::XmlMarkup.new(:target => xout)
    # make sure not to send html but text/xml
    headers["Content-Type"] = "text/xml; charset=utf-8"
    xml.instruct! :xml, :version=>"1.0"
    @lines = Line.find(:all, :order => 'id', :conditions => { :public => true })
    xml.lines {
      @lines.each do |line|
        xml.line do
          xml.id(line.name)
          line.stacks.each do |stack|
            xml.scan do
              xml.name(stack.name)
              xml.images(stack.num_images)
              xml.image do
                xml.url("#{DATA_IMAGE_FOLDER}#{stack[:name]}/512/merge_#{(stack.num_images / 2).to_s().rjust(3,'0')}.jpg")
              end
              @tags = stack.tags.find(:all, :conditions => ['active = true'])
              if (@tags.length > 0)
                
                @tags.each do |tag|
                  xml.tag do
                    xml.text(tag.tag)
                    conn = ActiveRecord::Base.connection();
                    @ontology_terms = conn.execute "select tag_term.term_id as fid from tag_term where tag_term.tag_id = #{tag.id}"
                    if  (DATA_ACCESS_HASH && @ontology_terms.length > 0) || (!DATA_ACCESS_HASH && @ontology_terms.num_tuples > 0)
                      xml.terms{
                        @ontology_terms.each do |fid|
                          if DATA_ACCESS_HASH
                            xml.fid(fid['fid'])
                          else
                            xml.fid(fid[0])
                          end
                        end                        
                      }
                    end
                    if tag.image_num != nil
                      xml.url("#{DATA_IMAGE_FOLDER}#{stack[:name]}/512/marge_#{tag.image_num.to_s().rjust(3,'0')}.jpg")
                      xml.x(tag.x_offset)
                      xml.y(tag.y_offset)                    
                    end
                  end
                end
                
              end
            end
          end
        end
      end
    }
    render :text => xout
  end
  
end


