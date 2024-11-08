
MRuby::Gem::Specification.new('mruby-rake') do |spec|
  spec.rbfiles << Dir.glob("#{dir}/mrblib/rake/*.rb")

  spec.add_dependency "mruby-dir"
  spec.add_dependency "mruby-io"
  spec.add_dependency "mruby-optparse"
  spec.add_dependency "mruby-process"
  spec.add_dependency "mruby-file-stat"
  spec.add_dependency "mruby-array-ext"
  spec.add_dependency "mruby-dir-glob"
  spec.add_dependency "mruby-require", ">= 0.1.0", :github => "ixday/mruby-require"

  spec.license = 'MIT'
  spec.author  = 'ksss <co000ri@gmail.com>'

  next if spec.for_windows?

  mruby_rake_dir = File.join(build.build_dir, "bin")
  mruby_rake_path = File.join(mruby_rake_dir, "mrake")
  mruby_rake_src_path = File.join(__dir__, "bin", "mrake")

  build.bins << "mrake"

  directory mruby_rake_dir

  file mruby_rake_path => [__FILE__, mruby_rake_dir, mruby_rake_src_path] do |t|
    FileUtils.cp(mruby_rake_src_path, t.name)
    chmod(0755, t.name)
  end
end
