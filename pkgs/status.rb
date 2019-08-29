#!/usr/local/bin/ruby

require 'ap'
require 'timeout'
require 'irb'

###

W = 40
S = %w[ unknown running starting pending failed empty importing succeeded ]

alias :p :ap

### 

def sp n
  ' ' * ( W - n )
end

def ps (*a)
  a.each {
    |x|
    puts x, ""
  }
end

###

def main (i = false)
  dat = {}
  out = ''

  Dir.glob('*.log').each {
    | logf |

    q = ''
    stat = \
      if File.empty?(logf)
        'empty'
      else
        q = %x[ grep 'Created builds:' -A 20 "#{logf}" | grep -v ^\- | grep -v ^$ | tr -s ' ' ]
  
        q.each_line.select { |x| x =~ /^ [0-9]/ }.last
      end
    
    stat ||= \
      begin
        %x[ copr-cli status #{q.split("\n").first.split.last} ]
      rescue
        'unknown'
      end
      
    stat = stat.split.last
      
    binding.irb unless S.include? stat
      
     
    dat[stat] ||= []
    dat[stat] << logf.split(?.).first.split(?-)[1..-1].join(?-)

    if i && logf =~ /#{i}/
      ps File.read(logf), "\n" + logf + ": " + stat

      binding.irb
    end

    File.delete(logf) if stat == 'succeeded'
  }

  dat.keys.sort.each {
    | k |
    v = dat[k]
    
    out += "\n>>> #{k} <<<\n"
    
    l = 0
    v.each_with_index {
      |n, i|
      
      if i % 2 == 0
        l = n.length
        out += "      #{n}"
      else
        out += "#{sp l} #{n}\n"
        l = 0
      end
    }
    
    out += "\n" unless l == 0
  }

  out + "\n > "
end

###

Dir.chdir ARGV.first if ARGV.any?

loop {
  begin
    x = main
    system "clear"
    print x
  
    r = Timeout.timeout(30) {
       $stdin.gets
    }
  rescue Timeout::Error
    retry
  end
  
  r ||= ''
  r.chomp!
  break if r.empty?
  
  main r
}

puts '=> exit'
