module Rake
  class Application

    attr_accessor :tasks
    attr_accessor :last_description

    DEFAULT_RAKEFILES = %w[Rakefile rakefile Rakefile.rb rakefile.rb]

    def initialize
      @rakefiles = DEFAULT_RAKEFILES.dup
      @rakefile = nil
      @original_dir = Dir.pwd
      @tasks = Hash.new { |h, k| h[k] = Rake::FileTask.define_task(k) if File.exist?(k)}
      @last_description = ""
      @scope = ""
    end

    def run
      init
      load_rakefile
      top_level
    rescue Exception => e
      puts "mrake aborted!"
      p e
      Dir.chdir(@original_dir)
    end

    def init()
      ENV.fetch("RUBYLIBS", "").split(":").each {|v| $:.push(v)}
      @argv = handle_options ARGV.dup
    end

    def in_namespace(name)
      @scope = name + ":"
      yield(self)
      self
    ensure
      @scope = ""
    end

    def define_task(task_klass, *args, &block)
      name, deps = resolve_args(args)
      scope, description, @last_description = @scope, @last_description, ""
      t = @tasks.fetch(scope + name) {|n| @tasks.store(n, task_klass.new(name))}
      t.enhance(deps.map{|d| scope + d.to_s}, &block)
      t.description = description if description != ""
      t
    end

    def resolve_args(args)
      task_name = args.first
      case task_name
      when Hash
        n = task_name.keys[0]
        [n.to_s, task_name[n].flatten]
      else
        [task_name.to_s, []]
      end
    end

    def load_rakefile
      rakefile, location = find_rakefile
      fail "No Rakefile found (looking for: #{@rakefiles.join(', ')})" if rakefile.nil?
      @rakefile = rakefile
      print_load_file File.expand_path(@rakefile) if location != @original_dir
      Dir.chdir(location)
      load(File.expand_path(@rakefile)) if @rakefile && @rakefile != ''
    end

    def top_level
      if options[:show_tasks]
        display_tasks_and_comments
      elsif options[:show_prereqs]
        display_prerequisites
      else
        @argv << 'default' if @argv.length == 0
        @argv.each do |arg|
          if Rake.application.tasks.has_key?(arg)
            @tasks[arg].invoke
          else
            fail "Don't know how to build task '#{arg}'"
          end
        end
      end
    end

    def find_rakefile
      here = Dir.pwd
      until (fn = have_rakefile)
        Dir.chdir("..")
        return nil if Dir.pwd == here
        here = Dir.pwd
      end
      [fn, here]
    ensure
      Dir.chdir(@original_dir)
    end

    def have_rakefile
      @rakefiles.each do |fn|
        if File.exist?(fn)
          return fn
        end
      end
      nil
    end

    def print_load_file(filename) = puts "(in : #{filename})"

    # Application options from the command line
    def options() = (@options ||= {})

    def handle_options(argv) # :nodoc:
      set_default_options

      OptionParser.new do |opts|
        opts.banner = "mrake [-f rakefile] {options} targets..."
        opts.separator ""
        opts.separator "Options are ..."

        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit
        end

        standard_rake_options.each { |args| opts.on(*args) }
        opts.environment("RAKEOPT")
      end.parse(argv)
    end

    def standard_rake_options()
      [
        ["--prereqs", "-P",
          "Display the tasks and dependencies, then exit.",
          lambda { |_| options[:show_prereqs] = true }
        ],
        ["--rakefile", "-f [FILENAME]",
          "Use FILENAME as the rakefile to search for.",
          lambda { |value|
            value ||= ""
            @rakefiles.clear
            @rakefiles << value
          }
        ],
        ["--tasks", "-T [PATTERN]",
          "Display the tasks with descriptions, then exit.",
          lambda { |_| options[:show_tasks] = true }
        ],
      ]
    end

    def display_prerequisites # :nodoc:
      @tasks.each do |_, t|
        puts "mrake #{t.name}"
        t.prerequisites.each { |pre| puts "    #{pre}" }
      end
    end

    def display_tasks_and_comments
      @tasks.sort.each do |k, v|
        puts "mrake #{k} # #{v.description}" unless v.description.empty?
      end
    end

    def set_default_options # :nodoc:
      options[:show_tasks] = false
      options[:show_prereqs] = false
    end
  end
end
