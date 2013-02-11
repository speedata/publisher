def get_rootdir(ctx)
  url = ctx.environments.first["page"]["url"]
  # remove last element, then change /abc to ../
  path = url.gsub(/(.*)\/[^\/]+$/,'\1')
  if path.empty?
    "."
  else
    path.gsub(/\/[^\/]+/,"../").gsub(/.$/,"")
  end
end


module Jekyll

  class OtherLanguages < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      rootdir = get_rootdir(context)
    	pagename = context.environments.first["page"]["url"]
      case pagename
      when "/index-de.html"
        %Q!Andere Sprache: <a href="index.html">Englisch</a>!
      when "/index.html"
        %Q!Other language: <a href="index-de.html">German</a>!
      else
        case pagename.match(/^\S+-(..)/) and pagename.match(/^\S+-(..)/)[1]
      	when "de"
      		%Q!Andere Sprache: <a href="#{rootdir}#{pagename.gsub(/-de/,'-en')}">Englisch</a>!
      	else
      		%Q!Other language: <a href="#{rootdir}#{pagename.gsub(/-en/,'-de')}">German</a>!
      	end
      end
    end
  end

  class StartPageTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      rootdir = get_rootdir(context)
      pagename = context.environments.first["page"]["url"]
      case pagename.match(/^\S+-(..)/) and pagename.match(/^\S+-(..)/)[1]
      when "de"
        %Q!<a href="#{rootdir}/index-de.html">Startseite</a>!
      else
        %Q!<a href="#{rootdir}/index.html">Start page</a>!
      end
    end
  end

  class ElementReferenceTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      rootdir = get_rootdir(context)
      pagename = context.environments.first["page"]["url"]
      case pagename.match(/^\S+-(..)/) and pagename.match(/^\S+-(..)/)[1]
      when "de"
        %Q!<a href="#{rootdir}/commands-de/layout.html">Elementreferenz</a>!
      else
        %Q!<a href="#{rootdir}/commands-en/layout.html">Element reference</a>!
      end
    end
  end

  class StartImageTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      pagename = context.environments.first["page"]["url"]
      rootdir = get_rootdir(context)
      pagename_match = pagename.match(/^\/?\S+-(..)/)
      if pagename_match and pagename_match[1] == "de" then
        %Q!<a href="#{rootdir}/index-de.html"><img src="#{rootdir}/images/publisher_logo.png" alt="Startseite"></a>!
      else
        %Q!<a href="#{rootdir}/index.html"><img src="#{rootdir}/images/publisher_logo.png" alt="Start page"></a>!
      end
    end
  end

  class RootDir < Liquid::Tag

    def initialize(tag_name,text,tokens)
      super
    end

    def render(context)
      get_rootdir(context)
    end
  end
end



Liquid::Template.register_tag('link_other_language', Jekyll::OtherLanguages)
Liquid::Template.register_tag('start_page', Jekyll::StartPageTag)
Liquid::Template.register_tag('elementreference', Jekyll::ElementReferenceTag)
Liquid::Template.register_tag('startimage', Jekyll::StartImageTag)
Liquid::Template.register_tag('rootdir', Jekyll::RootDir)
