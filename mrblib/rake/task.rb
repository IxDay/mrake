module Rake
  class Task
    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end

    attr_reader :prerequisites
    attr_accessor :description

    def initialize(name)
      @name = name
      @prerequisites = []
      @actions = []
      @already_invoked = false
      @description = ""
    end

    def invoke
      return if @already_invoked
      return unless needed?

      @prerequisites.each do |p|
        Rake.application.tasks[p].invoke
      end
      @actions.each do |b| b.call(self) end
      @already_invoked = true
    end

    def enhance(d, &b)
      @prerequisites |= d if d
      @actions << b if b
      self
    end

    def name = @name.to_s
    def reenable = (@already_invoked = false)
    def needed? = true
    def timestamp = Time.now

    class << self
      def [](task_name)
        Rake.application.tasks[task_name.to_s]
      end
    end
  end

  class FileTask < Task
    def needed? = (!File.exist?(name) || out_of_date?(timestamp))
    def timestamp = File.exist?(name) ? File::Stat.new(name).mtime : 0
    def out_of_date?(stamp) = @prerequisites.any? { |n| Rake.application.tasks[n].timestamp > stamp }
  end

  class FileCreationTask < FileTask
    # Is this file task needed?  Yes if it doesn't exist.
    def needed? = !File.exist?(name)

    # Time stamp for file creation task.  This time stamp is earlier
    # than any other time stamp.
    def timestamp = Rake::EARLY
  end
end
