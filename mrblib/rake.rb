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
