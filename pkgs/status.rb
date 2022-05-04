#!/usr/bin/ruby -W0

require 'ap'
require 'timeout'
require 'irb'

###

W = 40
S = %w[ unknown running starting pending failed empty importing succeeded canceled passed ]
E = "\n"
U = "https://copr.fedorainfracloud.org/coprs/build/"
C = ["    Bad exit status from /var/tmp/rpm-", 'Executing(%clean']

alias :p :ap

###

$succeeded = []

def sp n
  ' ' * ( W - n )
end

def ps (*a)
  a.each {
    |x|
    puts x, ""
  }
end

def warn(*_) ; end

###

def main (i = false, rmfile = false)
  dat = {}
  out = ''

  sg = 'bah'

#  Dir.glob('*.log').select { |x| x =~ /rubygem\-#{sg}/ }.each {
  Dir.glob('*.log').each {
    | logf |

    stat = ''
    qnt = File.read(logf)
    bnr = ''

    if qnt.nil? || qnt.empty?
      warn "#{logf}: empty log file"
      stat = 'empty'
    else
      bnr, stat = qnt.scan(/ Build ([0-9]+): (\S+)$/).last

      if ['running', 'pending'].include?(stat) \
          && qnt.include?("Max retries exceeded with url: ")
        begin
          stat = %x[ copr-cli status #{bnr} 2>&1 ]
          stat = stat.split.last
          warn "#{logf}: status: #{stat}"
        rescue
        end
      end

      stat = nil unless S.include? stat

      #if stat.nil? || stat.empty?
        q = %x[ grep '^Executing(%clean)' "#{logf}" ]
        stat = 'succeeded' unless q.nil? || q.empty?
      #end

      stat = 'unknown' if stat.nil? || stat.empty?
    end

    unless S.include? stat
      puts '[!] Unknown status: ' + stat
      binding.irb
    end

    name = logf.split(?.)[0..-2].join(?.)
    dat[stat] ||= []
    dat[stat] << name

    if i && name =~ /#{i}/
      t = false

      qnt = qnt.split(E).reject do
        |x|
        unless t
          t = C.detect {
            |c| x.start_with? c
          }

          x =~ /^(INFO|WARNING|Start|Finish): /
        else
          true
        end
      end

      ps qnt.last(200),
        '>> '+ logf + ": " + stat + E + '  '+ U + bnr

      binding.irb
    end

    if rmfile && stat == 'succeeded'
      File.delete logf
    end
  }

  if rmfile
    dat['succeeded'] ||= []
    $succeeded = dat['succeeded'] = (dat['succeeded'] + $succeeded).uniq
  end

  dat.keys.sort.each {
    | k |
    v = dat[k]

    next if v.nil? || v.empty?

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
rmfile = ( ARGV.any? && ARGV.first == '-r' )
ARGV.shift if rmfile

Dir.chdir ARGV.first if ARGV.any?

loop {
  begin
    x = main false, rmfile

    system "clear"
    print x

    r = Timeout.timeout(60) {
       $stdin.gets
    }
  rescue Timeout::Error
    retry
  end

  r ||= ''
  r.chomp!
  break if r.nil? || r.empty?

  main r
}

puts '=> exit'
