iscross = MRuby::Build.current.kind_of?(MRuby::CrossBuild)

MRuby::Gem::Specification.new('mruby-rake') do |spec|
  name = 'mrake'
  spec.rbfiles << Dir.glob("#{dir}/mrblib/rake/*.rb")
  spec.add_dependency "mruby-dir"
  spec.add_dependency "mruby-io"
  spec.add_dependency "mruby-optparse"
  spec.add_dependency "mruby-process"
  spec.add_dependency "mruby-require"
  spec.add_dependency "mruby-file-stat"
  spec.add_dependency "mruby-array-ext"
  spec.add_dependency "mruby-dir-glob"
  spec.license = 'MIT'
  spec.author  = 'ksss <co000ri@gmail.com>'

  if iscross
    mruby_rake_dir = "#{build.build_dir}/host-bin"
  else
    mruby_rake_dir = "#{build.build_dir}/bin"
  end

  if ENV['OS'] == 'Windows_NT'
    suffix = '.bat'
  else
    suffix = ''
  end

  mruby_rake = name + suffix
  mruby_rake_path = "#{mruby_rake_dir}/#{mruby_rake}"
  mruby_rake_src_path = "#{__dir__}/bin/#{mruby_rake}"

  if iscross
    build.products << mruby_rake_path
  else
    build.bins << mruby_rake
  end

  directory mruby_rake_dir

  file mruby_rake_path => [__FILE__, mruby_rake_dir, mruby_rake_src_path] do |t|
    FileUtils.cp(mruby_rake_src_path, t.name)
    chmod(0755, t.name)
  end
end
