#--
# Copyright 2003-2010 by Jim Weirich (jim.weirich@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#++
module Rake
  class << self
    def application() = @application ||= Rake::Application.new

    # Yield each file or directory component.
    def each_dir_parent(dir, &block)    # :nodoc:
      old_length, arr = nil, []
      while dir != "." && dir.length != old_length
        block ? yield(dir) : arr << dir
        old_length = dir.length
        dir = File.dirname(dir)
      end
      arr
    end
  end
end

class IO
  def readlines()
    return to_enum(:readlines, self) unless block_given?
    # the each line from mruby seem broken so we are fixing it this way
    each {|buf| buf.split("\n").each {|line| yield line}}
  end
end

# https://github.com/djberg96/ptools/blob/ptools-1.5.0/lib/ptools.rb#L80-L132
class File
  # The WIN32EXTS string is used as part of a Dir[] call in certain methods.
  if File::ALT_SEPARATOR
    MSWINDOWS = true
    if ENV['PATHEXT']
      WIN32EXTS = ".{#{ENV['PATHEXT'].tr(';', ',').tr('.', '')}}".downcase
    else
      WIN32EXTS = '.{exe,com,bat}'.freeze
    end
  else
    MSWINDOWS = false
  end

  if File::ALT_SEPARATOR
    private_constant :WIN32EXTS
    private_constant :MSWINDOWS
  end

  def self.which(program, path = ENV['PATH'])
    raise ArgumentError, 'path cannot be empty' if path.nil? || path.empty?

    # Bail out early if an absolute path is provided.
    if program =~ /^\/|^[a-z]:[\\\/]/i
      program += WIN32EXTS if MSWINDOWS && File.extname(program).empty?
      found = Dir.glob(program).first # need some fixes
      stat = File::Stat.new(found) if found
      if found &&  stat.executable?() && stat.directory?()
        return found
      else
        return nil
      end
    end

    # Iterate over each path glob the dir + program.
    path.split(File::PATH_SEPARATOR).each do |dir|
      dir = File.expand_path(dir)

      next unless File.exist?(dir) # In case of bogus second argument

      file = File.join(dir, program)

      # Dir[] doesn't handle backslashes properly, so convert them. Also, if
      # the program name doesn't have an extension, try them all.
      if MSWINDOWS
        file = file.tr(File::ALT_SEPARATOR, File::SEPARATOR)
        file += WIN32EXTS if File.extname(program).empty?
      end

      found = Dir.glob(file).first
      stat = File::Stat.new(found) if found

      # Convert all forward slashes to backslashes if supported
      if found && stat.executable?() && !stat.directory?()
        found.tr!(File::SEPARATOR, File::ALT_SEPARATOR) if File::ALT_SEPARATOR
        return found
      end
    end

    nil
  end
end
