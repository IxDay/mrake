module Rake
  module DSL
    def task(*args, &block) = Rake::Task.define_task(*args, &block)

    def file(*args, &block) = Rake::FileTask.define_task(*args, &block)

    def cd(path, &block)
      puts "cd #{path}"
      if block
        Dir.chdir(path, &block)
        puts "cd -"
      else
        Dir.chdir(path)
      end
    end

    def sh(command)
      puts command
      system command
    end

    def file_create(*args, &block) = Rake::FileCreationTask.define_task(*args, &block)

    def directory(*args, &block) # :doc:
      result = file_create(*args, &block)
      dir, _ = *Rake.application.resolve_args(args)
      Rake.each_dir_parent(dir) do |d|
        file_create d do |t|
          Rake.each_dir_parent(t.name).reverse.each { | d | Dir.mkdir(d) unless File.exist?(t.name) }
        end
      end
      result
    end
  end
end

