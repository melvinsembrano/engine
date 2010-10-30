module Locomotive
  module Liquid
    module Tags
      # Display the children pages of the site or the current page. If not precised, nav is applied on the current page.
      # The html output is based on the ul/li tags.
      #
      # Usage:
      #
      # {% nav site %} => <ul class="nav"><li class="on"><a href="/features">Features</a></li></ul>
      #
      class Nav < ::Liquid::Tag

        Syntax = /(#{::Liquid::Expression}+)?/

        def initialize(tag_name, markup, tokens, context)
          if markup =~ Syntax
            @site_or_page = $1 || 'page'
            @options = {}
            markup.scan(::Liquid::TagAttributes) { |key, value| @options[key.to_sym] = value }

            @options[:exclude] = Regexp.new(@options[:exclude].gsub(/"|'/, '')) if @options[:exclude]
          else
            raise ::Liquid::SyntaxError.new("Syntax Error in 'nav' - Valid syntax: nav <page|site> <options>")
          end

          super
        end

        def render(context)
          @current_page = context.registers[:page]

          source = context.registers[@site_or_page.to_sym]

          if source.respond_to?(:name) # site ?
            source = source.pages.index.first # start from home page
          else
            source = source.parent || source
          end

          output = source.children.map { |p| include_page?(p) ? render_child_link(p) : ''  }.join("\n")

           if @options[:no_wrapper] != 'true'
             output = %{<ul id="nav">\n#{output}</ul>}
           end

          output
        end

        private

        def include_page?(page)
          if page.templatized?
            false
          elsif @options[:exclude]
            (page.fullpath =~ @options[:exclude]).nil?
          else
            true
          end
        end

        def render_child_link(page)
          selected = @current_page._id == page._id ? ' on' : ''

          icon = @options[:icon] ? '<span></span>' : ''
          label = %{#{icon if @options[:icon] != 'after' }#{page.title}#{icon if @options[:icon] == 'after' }}

          %{
            <li id="#{page.slug.dasherize}" class="link#{selected}">
              <a href="/#{page.fullpath}">#{label}</a>
            </li>
          }.strip
        end

        ::Liquid::Template.register_tag('nav', Nav)
      end
    end
  end
end
