module Jekyll

  class Figure < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
    	str = @text.split
    	cls = nil
    	if str.delete(":shadow")
    		cls = "screenshot shadow"
    	else
    		cls = "screenshot"
    	end
    	"<a href='../images/#{str[0]}'><img src='../images/#{str[0]}' class='#{cls}'/></a>"
    end
  end

end

Liquid::Template.register_tag('figure', Jekyll::Figure)

