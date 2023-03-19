MRuby::Gem::Specification.new('mruby-rake') do |spec|
  spec.rbfiles << Dir.glob("#{dir}/mrblib/rake/*.rb")

  spec.add_dependency "mruby-dir"
  spec.add_dependency "mruby-io"
  spec.add_dependency "mruby-process"
  spec.add_dependency "mruby-file-stat"
  spec.add_dependency 'mruby-array-ext'
  spec.add_dependency "mruby-array-ext"
  spec.add_dependency "mruby-ostruct"
  spec.add_dependency "mruby-optparse"
  spec.license = 'MIT'
  spec.author  = 'ksss <co000ri@gmail.com>'
end
