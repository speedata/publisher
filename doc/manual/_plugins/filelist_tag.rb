
module Jekyll

  class FileList < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def direntry(filename,description)
      "<tr><td><a href='#{filename}/index.html'>#{filename}/</a></td><td style='padding-left: 40px;'>#{description}</td></tr>"
    end
    def filentry(filename,description)
      "<tr><td><a href='#{filename}'>#{filename}</a></td><td style='padding-left: 40px;'>#{description}</td></tr>"
    end

    def render(context)
      descriptions = {}
      @text.split(/;/).each do |entry|
        tmp = entry.match(/^(.*?)=(.*)$/)
        if tmp then
          descriptions[tmp[1]] = tmp[2]
        end
      end
      pageobj = context.environments.first["page"]
      str = []
      pagename = pageobj["url"]
      dir = pagename.gsub(/.(.*)\/index\.html/,'\1')
      lang = pagename.match(/^\S+-(..)/)[1]
      str << "<h1>"
      case lang
      when "de"
        str << "Dateiliste" 
      else
        str << "File list"
      end
      str << "</h1>"
      str << "<table>"
      unless pageobj["parentlink"] == false then
        str << direntry("..", "")
      end
      Dir.chdir(dir) {
        Dir.glob("*") { |file| unless file =~ /index.md$/ then
          if File.directory?(file) then
            str << direntry(file,descriptions[file])
          else
            str << filentry(file,descriptions[file])
          end
        end
        }
      }
      str << "</table>"
      str << "<div style='margin-top: 30px;'></div>"
      str.join("\n")
    end
  end

end

Liquid::Template.register_tag('filelist', Jekyll::FileList)

