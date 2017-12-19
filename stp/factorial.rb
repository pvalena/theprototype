#!/usr/bin/ruby

 fa = Hash.new{ |x, y| x[y] = y > 2 ? y * x[y-1] : 2 }

 ARGV.each { |s| puts "#{s} => #{fa[s.to_i]}" }
