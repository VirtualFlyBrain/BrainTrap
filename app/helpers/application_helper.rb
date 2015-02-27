# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def external_link_to(name, url)
    extimg = image_tag('external_12.gif', :alt => '(external link)', :title => 'Opens in a new window')
    return link_to(name + '&nbsp;' + extimg, url, :target => '_blank')
  end

  def link_to_flybase_cg(geneid)
    if geneid == nil
      return ''
    else
      return external_link_to('Flybase', "http://flybase.org/cgi-bin/uniq.html?caller=genejump&context=#{geneid}")
    end
  end

  def link_to_flybase_fbgn(fbgn)
    if fbgn == nil
      return ''
    else
      return external_link_to('Flybase', "http://flybase.org/reports/#{fbgn}.html")
    end
  end

  def link_to_flyprot_cpti(cpti)
    if cpti == nil
      return ''
    else
      name = 'Flyprot'
      url = "http://www.flyprot.org/stock_report.php?jump_to=#{cpti}"
      extimg = image_tag('external_12.gif', :alt => '(external link)', :title => 'Opens in a new window')
      #HACK: we need a javascript refresh for the flyprot page because the access cookie is not set on the first page visit!
      return link_to(name + '&nbsp;' + extimg, url, :target => '_blank',
        :onclick => "fp_window = window.open('#{url}');setTimeout('fp_window.location=\"#{url}\";', 1000);return false;")
    end
  end

  def link_to_kyoto(cpti)
    if cpti == nil
      return ''
    else
      return external_link_to('Kyoto Stock Center (listing pending)', "http://kyotofly.kit.jp/stocks/documents/CPTI.html")
    end
  end

end
