
module Jekyll

  class OtherLanguages < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
    	pagename = context.environments.first["page"]["url"]
    	lang = pagename.match(/description-(..)/)[1]
    	case lang
    	when "de"
    		%Q!Andere Sprache: <a href="..#{pagename.gsub(/-de/,'-en')}">Englisch</a>!
    	when "en"
    		%Q!Other language: <a href="..#{pagename.gsub(/-en/,'-de')}">German</a>!
    	end
    end
  end

  class StartPageTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      pagename = context.environments.first["page"]["url"]
      lang = pagename.match(/description-(..)/)[1]
      case lang
      when "de"
        %Q!<a href="../index-de.html">Startseite</a>!
      when "en"
        %Q!<a href="../index.html">Start page</a>!
      end
    end
  end

  class ElementReferenceTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      pagename = context.environments.first["page"]["url"]
      lang = pagename.match(/description-(..)/)[1]
      case lang
      when "de"
        %Q!<a href="../commands-de/layout.html">Elementreferenz</a>!
      when "en"
        %Q!<a href="../commands-en/layout.html">Element reference</a>!
      end
    end
  end

  class StartImageTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      pagename = context.environments.first["page"]["url"]
      case pagename
      when "/index-de.html"
        %Q!<a href="index-de.html"><img src="images/publisher_logo.png" alt="Startseite"></a>!
      when "/index.html"
        %Q!<a href="index.html"><img src="images/publisher_logo.png" alt="Start page"></a>!
      when /description-de/
        %Q!<a href="../index-de.html"><img src="../images/publisher_logo.png" alt="Startseite"></a>!
      else
        %Q!<a href="../index.html"><img src="../images/publisher_logo.png" alt="Start page"></a>!
      end
    end
  end

end

Liquid::Template.register_tag('link_other_language', Jekyll::OtherLanguages)
Liquid::Template.register_tag('start_page', Jekyll::StartPageTag)
Liquid::Template.register_tag('elementreference', Jekyll::ElementReferenceTag)
Liquid::Template.register_tag('startimage', Jekyll::StartImageTag)
