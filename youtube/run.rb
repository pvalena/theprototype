#!/usr/bin/ruby
#
# ./run.rb [options] events.csv links.csv [video_directory1, video_dir2 ...]
#
#   CSVs can be downloaded from sched, exported/converted to csv.
#   You also need to edit the variables in the class Upload (between the # lines).
#
#   events.csv
#     - list of talks with event_key, title, description...
#     - original name f.e. devconfcz2020a-event-list-2020-02-26-14-45-16
#     - remove the description lines with anything other than talks (keep the first line)
#
#   links.csv
#     - list of titles and links
#     - original name f.e. session-links-devconfcz2020a-2020-02-26
#
#   done.txt
#     - expected to contain IDs to skip
#
#   Options
#     - In alphabetical order!
#
#       -c    check inputs consistency and quit
#               helpful to check the created descriptions
#               or to check for titles that are too long.
#
#       -d    debug
#
#       -s    silent; do not write out what is done
#
#   Examples:
#     - Print out the ID, Title and Descriptions of talks from input files.
#       ./run.rb -c -d DC_2021_events.csv DC_2021_links.csv \
#       "/run/media/lpcs/Seagate Expansion Drive/Media/DevConfCZ_2021-processed/test"
#
#

require 'csv'
require File.join __dir__, 'local_execute.rb'
require 'sanitize'

begin
  require 'ap'
  alias :pp :ap
rescue LoadError
end

class Upload

######################################
  FMS = %w{ mpg mp4 mpeg mkv }
  SLEEP = 15
  UPL_SCR = 'upload_video.sh'
  DONEFILE = 'done.txt'

  ALLOW = ['Presentation', 'Keynote', 'Workshop', 'Talk', 'Meetup']

  SUFFIX = ' - DevConf.CZ 2021'
  LIST = 'DevConfCZ 2021'
  FOOTER = <<EOF
EOF
#--
#Recordings of talks at DevConf are a community effort. Unfortunately not everything works perfectly every time. If you're interested in helping us #improve, let us know.
######################################

  include LocalExecute

  attr_accessor :onlycheck

  def self.start argv
    me = self.new argv
    me.check
    me.run unless me.onlycheck
    me
  end

  def initialize argv
    @ups = File.join __dir__, UPL_SCR
    unless !@ups.nil? && File.readable?(@ups)
      error("Could not locate upload_script: #{@ups}")
    end

    @onlycheck = argv.first == '-c'
    argv.shift if @onlycheck

    @debug = argv.first == '-d'
    argv.shift if @debug

    @silent = argv.first == '-s'
    argv.shift if @silent

    @events = load_csv(argv.shift)
    @links = load_csv(argv.shift)

    @events_keys = {}
    @links_keys = {}

    @events[0].each_with_index { |w, i| @events_keys[w] = i }
    @links[0].each_with_index { |w, i| @links_keys[w] = i }

    @events = @events[1..]
    @links = @links[1..]

    @dirs = argv
  end

  def check
    @events = @events.select {
      |e|
      unless x = \
        ALLOW.include?(event(e, 'event_subtype')) \
          && \
        event(e, 'active') == 'Y'
        verb "Rejected: " + event(e, 'event_key', 'active', 'event_subtype', 'name').join(' | ')
      end

      x
    }

    tln = @events.select {
      |e|
      event(e, 'name').length >= (80 - SUFFIX.length)
    }
    unless tln.empty?
      tln.each {
        |e|
        puts event(e, 'event_key', 'name').join(' | ')
      }
      error "The above talks have titles too long."
    end

    if @onlycheck
      @events = @events.each {
        |e|
        id = event(e, 'event_key')
        get_text id
      }
    end
  end

  def run
    error 'this should not run now' if @onlycheck

    @dirs.each do |dr|
      File.directory?(dr) || error("Is not a directory: #{dr}")

      puts "\n>> Directory: #{dr}"

      Dir.each_child dr do |vid|
        vid = File.join dr, vid

        ext = File.extname(vid)[1..]

        unless FMS.include? ext
          puts "Ignoring file: #{vid}"
          next
        end
        File.readable?(vid) || error("File not readable: #{vid}")
        unless @silent
          puts
          verb "Video file: #{File.basename(vid)}"
        end

        upload vid, ext
      end
    end
  end

  def upload vid, ext
    ename = File.basename vid, ".#{ext}"
    id = ename.split.first

    if is_done(id)
      puts "Video already uploaded, skipping." unless @silent
      return
    end

    begin
      title, description = get_text id
    rescue Exception
      return
    end

    verb "Uploading video, ID: #{id}" if @silent

    out, err = ['', '']
    suc = local_execute \
      [ @ups,
        vid,
        title,
        description,
        LIST
      ],
      out: out,
      err: err,
      debug: @debug

    puts out unless out.empty?
    puts err unless err.empty?

    #suc = false unless out.include?('was successfully uploaded')
    suc || error("Upload FAILED.")

    verb 'OK' + $/
    set_done id
    sleep SLEEP
  end

  def load_csv file
    file.nil? && error("Arg missing.")
    File.readable?(file) || error("Could not read: #{file}")
    CSV.read(file)
  end

  def acc whr, line, *keys
    x = keys.map {
      |key|
        i = whr[key]
        i.nil? && error("Key not found: #{key}")
        line[i]
      }
    x.one? && x = x.first
    x
  end

  def event e, *keys
    acc @events_keys, e, *keys
  end
  def link l, *keys
    acc @links_keys, l, *keys
  end

  def get_text id
    eve = @events.detect {
      |e|
      event(e, 'event_key') == id
    }
    eve.nil? && error("Event for video '#{id}' not found.")

    name = event(eve, 'name')
    desc = event(eve, 'description')
    speakers = event(eve, 'speakers')

    lnk = @links.detect {
      |l|
      name.start_with? link(l, 'name')
    }
    lnk.nil? && error("Link for video '#{name}' not found.")
    shortlink = link(lnk, 'shortlink')

    title = sanitize(name + SUFFIX)
    description = sanitize <<EOD
Speakers: #{speakers}

#{desc}

Schedule: #{shortlink}
#{FOOTER}
EOD

    if @debug
      puts "================================================", ""
      verb "ID: #{id}"
      verb "Title: #{title}"
      verb "Description:"
      #description.each_line{ |l| puts (" "*4 + l) }
      description.each_line{ |l| puts l }
    end

    [title, description]
  end

  def sanitize x
    Sanitize.fragment \
      x.gsub("<br>", $/)
       .gsub("<li>", $/ + ' - ')
       .gsub("<li dir='ltr'>", $/ + ' - ')
       .gsub("<br />", $/)
       .gsub("<br/>", $/)
  end

  def verb x
    puts "> " + x
  end

  def is_done id
    d = File.readlines(DONEFILE)
    d.include?(id + $/)
  end

  def set_done id
    File.write(DONEFILE, id + $/, mode: 'a')
  end

  def error m
      puts "================================================", ""
      abort("Error: #{m}")
  end
end

Upload.start(ARGV)
