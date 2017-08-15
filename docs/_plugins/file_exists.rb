module Liquid
  class FileExistsCondition < Condition
    def initialize(path)
      @path = path
    end

    def evaluate(context = Context.new)
      path = Template.parse(@path).render context
      return locate_include_file(context, path)
    end

    def locate_include_file(context, file)
      includes_dirs = tag_includes_dirs(context)
      includes_dirs.each do |dir|
        path = File.join(dir.to_s, file.to_s).strip
        return path if File.file?(path)
      end
      return false
    end

    def tag_includes_dirs(context)
      context.registers[:site].includes_load_paths.freeze
    end
  end

  class IfFileExists < Block
    def initialize(tag_name, markup, options)
      super
      @blocks = []
      push_block('iffileexists', markup)
    end

    def unknown_tag(tag, markup, tokens)
      if tag == 'else'
        push_block(tag, markup)
      else
        super
      end
    end

    def render(context)
      context.stack do
        @blocks.each do |block|
          if block.evaluate(context)
            return render_all(block.attachment, context)
          end
        end
        ''.freeze
      end
    end

    def push_block(tag, markup)
      block = if tag == 'else'
        ElseCondition.new
      elsif tag == 'iffileexists'
        FileExistsCondition.new(markup)
      else
        raise(SyntaxError.new("tag '#{tag}' not supported"))
      end

      @blocks.push(block)
      @nodelist = block.attach(Array.new)
    end
  end
end

Liquid::Template.register_tag('iffileexists', Liquid::IfFileExists)
