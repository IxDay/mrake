module Rake
  class Application
    attr_accessor :tasks

    DEFAULT_RAKEFILES = %w[Rakefile rakefile Rakefile.rb rakefile.rb]

    def initialize
      @rakefiles = DEFAULT_RAKEFILES.dup
      @rakefile = nil
      @original_dir = Dir.pwd
      @tasks = {}
      # List of the top level task names (task names from the command line).
      @top_level_tasks = []
    end

    def run
      init_options
      load_rakefile
      top_level
    rescue Exception => e
      puts "mrake aborted!"
      p e
      Dir.chdir(@original_dir)
    end

        def top_level_tasks
      @top_level_tasks
    end

    # Application options from the command line
    def options
      @options ||= ::OpenStruct.new
    end

    def set_default_options
      options.always_multitask           = false
      options.backtrace                  = false
      options.build_all                  = false
      options.dryrun                     = false
      options.ignore_deprecate           = false
      options.ignore_system              = false
      options.job_stats                  = false
      options.load_system                = false
      options.nosearch                   = false
      options.rakelib                    = %w[rakelib]
      options.show_all_tasks             = false
      options.show_prereqs               = false
      options.show_task_pattern          = nil
      options.show_tasks                 = nil
      options.silent                     = false
      options.suppress_backtrace_pattern = nil
      # options.thread_pool_size           = Rake.suggested_thread_count # MRUBY: threading support?
      options.trace                      = false
      # options.trace_output               = $stderr
      # options.trace_rules                = false
    end

    def sort_options(options)
      options.sort_by do |opt|
        opt.select { |o| o.is_a?(String) && o =~ /^-/ }.map(&:downcase).sort.reverse
      end
    end

        # A list of all the standard options used in rake, suitable for
    # passing to OptionParser.
    def standard_rake_options
      sort_options(
        [
          ["--all", "-A",
            "Show all tasks, even uncommented ones (in combination with -T or -D)",
            lambda { |value|
              options.show_all_tasks = value
            }
          ],
          # ["--backtrace=[OUT]",
          #   "Enable full backtrace.  OUT can be stderr (default) or stdout.",
          #   lambda { |value|
          #     options.backtrace = true
          #     select_trace_output(options, "backtrace", value)
          #   }
          # ],
          # ["--build-all", "-B",
          #  "Build all prerequisites, including those which are up-to-date.",
          #  lambda { |value|
          #    options.build_all = true
          #  }
          # ],
          ["--comments",
            "Show commented tasks only",
            lambda { |value|
              options.show_all_tasks = !value
            }
          ],
          # ["--describe", "-D [PATTERN]",
          #   "Describe the tasks (matching optional PATTERN), then exit.",
          #   lambda { |value|
          #     select_tasks_to_show(options, :describe, value)
          #   }
          # ],
          # ["--directory", "-C [DIRECTORY]",
          #   "Change to DIRECTORY before doing anything.",
          #   lambda { |value|
          #     Dir.chdir value
          #     @original_dir = Dir.pwd
          #   }
          # ],
          # ["--dry-run", "-n",
          #   "Do a dry run without executing actions.",
          #   lambda { |value|
          #     Rake.verbose(true)
          #     Rake.nowrite(true)
          #     options.dryrun = true
          #     options.trace = true
          #   }
          # ],
          # ["--execute", "-e CODE",
          #   "Execute some Ruby code and exit.",
          #   lambda { |value|
          #     eval(value)
          #     exit
          #   }
          # ],
          # ["--execute-print", "-p CODE",
          #   "Execute some Ruby code, print the result, then exit.",
          #   lambda { |value|
          #     puts eval(value)
          #     exit
          #   }
          # ],
          # ["--execute-continue",  "-E CODE",
          #   "Execute some Ruby code, " +
          #   "then continue with normal task processing.",
          #   lambda { |value| eval(value) }
          # ],
          # ["--jobs",  "-j [NUMBER]",
          #   "Specifies the maximum number of tasks to execute in parallel. " +
          #   "(default is number of CPU cores + 4)",
          #   lambda { |value|
          #     if value.nil? || value == ""
          #       value = Float::INFINITY
          #     elsif value =~ /^\d+$/
          #       value = value.to_i
          #     else
          #       value = Rake.suggested_thread_count
          #     end
          #     value = 1 if value < 1
          #     options.thread_pool_size = value - 1
          #   }
          # ],
          # ["--job-stats [LEVEL]",
          #   "Display job statistics. " +
          #   "LEVEL=history displays a complete job list",
          #   lambda { |value|
          #     if value =~ /^history/i
          #       options.job_stats = :history
          #     else
          #       options.job_stats = true
          #     end
          #   }
          # ],
          # ["--libdir", "-I LIBDIR",
          #   "Include LIBDIR in the search path for required modules.",
          #   lambda { |value| $:.push(value) }
          # ],
          # ["--multitask", "-m",
          #   "Treat all tasks as multitasks.",
          #   lambda { |value| options.always_multitask = true }
          # ],
          # ["--no-search", "--nosearch",
          #   "-N", "Do not search parent directories for the Rakefile.",
          #   lambda { |value| options.nosearch = true }
          # ],
          # ["--prereqs", "-P",
          #   "Display the tasks and dependencies, then exit.",
          #   lambda { |value| options.show_prereqs = true }
          # ],
          # ["--quiet", "-q",
          #   "Do not log messages to standard output.",
          #   lambda { |value| Rake.verbose(false) }
          # ],
          # ["--rakefile", "-f [FILENAME]",
          #   "Use FILENAME as the rakefile to search for.",
          #   lambda { |value|
          #     value ||= ""
          #     @rakefiles.clear
          #     @rakefiles << value
          #   }
          # ],
          # ["--rakelibdir", "--rakelib", "-R RAKELIBDIR",
          #   "Auto-import any .rake files in RAKELIBDIR. " +
          #   "(default is 'rakelib')",
          #   lambda { |value|
          #     options.rakelib = value.split(File::PATH_SEPARATOR)
          #   }
          # ],
          # ["--require", "-r MODULE",
          #   "Require MODULE before executing rakefile.",
          #   lambda { |value|
          #     begin
          #       require value
          #     rescue LoadError => ex
          #       begin
          #         rake_require value
          #       rescue LoadError
          #         raise ex
          #       end
          #     end
          #   }
          # ],
          # ["--rules",
          #   "Trace the rules resolution.",
          #   lambda { |value| options.trace_rules = true }
          # ],
          # ["--silent", "-s",
          #   "Like --quiet, but also suppresses the " +
          #   "'in directory' announcement.",
          #   lambda { |value|
          #     Rake.verbose(false)
          #     options.silent = true
          #   }
          # ],
          # ["--suppress-backtrace PATTERN",
          #   "Suppress backtrace lines matching regexp PATTERN. " +
          #   "Ignored if --trace is on.",
          #   lambda { |value|
          #     options.suppress_backtrace_pattern = Regexp.new(value)
          #   }
          # ],
          # ["--system",  "-g",
          #   "Using system wide (global) rakefiles " +
          #   "(usually '~/.rake/*.rake').",
          #   lambda { |value| options.load_system = true }
          # ],
          # ["--no-system", "--nosystem", "-G",
          #   "Use standard project Rakefile search paths, " +
          #   "ignore system wide rakefiles.",
          #   lambda { |value| options.ignore_system = true }
          # ],
          # ["--tasks", "-T [PATTERN]",
          #   "Display the tasks (matching optional PATTERN) " +
          #   "with descriptions, then exit. " +
          #   "-AT combination displays all of tasks contained no description.",
          #   lambda { |value|
          #     select_tasks_to_show(options, :tasks, value)
          #   }
          # ],
          # ["--trace=[OUT]", "-t",
          #   "Turn on invoke/execute tracing, enable full backtrace. " +
          #   "OUT can be stderr (default) or stdout.",
          #   lambda { |value|
          #     options.trace = true
          #     options.backtrace = true
          #     select_trace_output(options, "trace", value)
          #     Rake.verbose(true)
          #   }
          # ],
          # ["--verbose", "-v",
          #   "Log message to standard output.",
          #   lambda { |value| Rake.verbose(true) }
          # ],
          # ["--version", "-V",
          #   "Display the program version.",
          #   lambda { |value|
          #     puts "rake, version #{Rake::VERSION}"
          #     exit
          #   }
          # ],
          # ["--where", "-W [PATTERN]",
          #   "Describe the tasks (matching optional PATTERN), then exit.",
          #   lambda { |value|
          #     select_tasks_to_show(options, :lines, value)
          #     options.show_all_tasks = true
          #   }
          # ],
          # ["--no-deprecation-warnings", "-X",
          #   "Disable the deprecation warnings.",
          #   lambda { |value|
          #     options.ignore_deprecate = true
          #   }
          # ],
        ])
    end

    # Read and handle the command line options.  Returns the command line
    # arguments that we didn't understand, which should (in theory) be just
    # task names and env vars.
    def handle_options(argv)
      puts 'handle_options'
      set_default_options

      result = ::OptionParser.new do |opts|
        puts 'OptionParser'
        opts.banner = "#{@name} [-f rakefile] {options} targets..."
        opts.separator ""
        opts.separator "Options are ..."

        # opts.on_tail("-h", "--help", "-H", "Display this help message.") do
        #  puts opts
        #  exit
        # end

        # standard_rake_options.each do |args|
        #   opts.on(*args)
        # end
        opts.environment("RAKEOPT")
      end.parse(argv)

      puts "handle_options - end"
      return result
    end

        # Read and handle the command line options.  Returns the command line
    # arguments that we didn't understand, which should (in theory) be just
    # task names and env vars.
    def handle_options(argv)
      puts 'handle_options'
      set_default_options

      result = ::OptionParser.new do |opts|
        puts 'OptionParser'
        opts.banner = "#{@name} [-f rakefile] {options} targets..."
        opts.separator ""
        opts.separator "Options are ..."

        # opts.on_tail("-h", "--help", "-H", "Display this help message.") do
        #  puts opts
        #  exit
        # end

        # standard_rake_options.each do |args|
        #   opts.on(*args)
        # end
        opts.environment("RAKEOPT")
      end.parse(argv)

      puts "handle_options - end"
      return result
    end

    # Invokes a task with arguments that are extracted from +task_string+
    def invoke_task(task_string)
      name, args = parse_task_string(task_string)
      # t = self[name] # MRUBY: TODO: not the same.
      t = @tasks[name]
      if t
        puts "Invoking task: '#{name}'"
      else
        raise "Could not execute! Task is undefined: '#{name}'"
      end
      t.invoke(*args)
    end

    def parse_task_string(string)
      /^([^\[]+)(?:\[(.*)\])$/ =~ string.to_s

      name           = $1
      remaining_args = $2

      return string, [] unless name
      return name,   [] if     remaining_args.empty?

      args = []

      begin
        /\s*((?:[^\\,]|\\.)*?)\s*(?:,\s*(.*))?$/ =~ remaining_args

        remaining_args = $2
        args << $1.gsub(/\\(.)/, '\1')
      end while remaining_args

      return name, args
    end

    # Initialize the command line parameters, options, and app name.
    def init_options(app_name="rake", argv = ARGV)
      @name = app_name
      @argv = argv.dup
      collect_command_line_tasks(handle_options(@argv))
    end

    def define_task(task_klass, *args, &block)
      name, deps = resolve_args(args)
      t = task_klass.new(name)
      @tasks[name] = t
      deps = deps.map{|d| d.to_s}
      t.enhance(deps, &block)
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

    # Run the top level tasks of a Rake application.
    def top_level
      if Rake.application.tasks.has_key?('default')
      # MRUBY: support for threading?
        @tasks['default'].invoke
      # run_with_threads do
      else
        if options.show_tasks
        fail "Don't know how to build task 'default'"
          display_tasks_and_comments
        elsif options.show_prereqs
          display_prerequisites
        else
          top_level_tasks.each do |task_name|
            invoke_task(task_name)
          end
        end
      end
    end

    # Collect the list of tasks on the command line.  If no tasks are
    # given, return a list containing only the default task.
    # Environmental assignments are processed at this time as well.
    #
    # `args` is the list of arguments to peruse to get the list of tasks.
    # It should be the command line that was given to rake, less any
    # recognised command-line options, which OptionParser.parse will
    # have taken care of already.
    def collect_command_line_tasks(args)
      @top_level_tasks = []
      args.each do |arg|
        if arg =~ /^(\w+)=(.*)$/m
          ENV[$1] = $2  # MRUBY: support for ENV?
        else
          @top_level_tasks << arg unless arg =~ /^-/
        end
      end
      end
      @top_level_tasks.push(default_task_name) if @top_level_tasks.empty?
    end

    # Default task name ("default").
    # (May be overridden by subclasses)
    def default_task_name
      "default"
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

    def print_load_file(filename)
      puts "(in : #{filename})"
    end
  end
end
