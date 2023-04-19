module Rake
  EARLY = Object.new
  EARLY.extend Comparable
  def EARLY.to_s = "<EARLY TIME>"
  def EARLY.<=>(_) = -1
end
