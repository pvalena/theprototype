#!/usr/bin/ruby
#
# ./run.rb events.csv links.csv [video_directory1, video_dir2 ...]
#
#   CSVs are downloaded from sched, exported/converted via google sheets
#
#   events.csv
#     - list of talks with event_key, title, description...
#     - original name f.e. devconfcz2020a-event-list-2020-02-26-14-45-16
#
#   links.csv
#     - list of titles and links
#     - original name f.e. session-links-devconfcz2020a-2020-02-26
#

require 'csv'
require File.join __dir__, 'local_execute.rb'
require 'sanitize'

begin
  require 'ap'
  alias_method :ap, :pp
rescue LoadError
end

class Upload
  FMS = %w{ mpg mp4 mpeg mkv }
  SLEEP = 15
  UPL_SCR = 'upload_video.sh'
  DONEFILE = 'done.txt'

  SUFFIX = ' - DevConf.CZ 2020'
  FOOTER = <<EOF

--
Recordings of talks at DevConf are a community effort. Unfortunately not everything works perfectly every time. If you're interested in helping us improve, let us know.
EOF

  include LocalExecute

  def self.start argv
    me = self.new argv
    me.check
    me.run unless @onlycheck
    me
  end

  def initialize argv
    @ups = File.join __dir__, UPL_SCR
    unless !@ups.nil? && File.readable?(@ups)
      abort("Could not locate upload_script: #{@ups}")
    end

    @debug = argv.first == '-d'
    argv.shift if @debug

    @onlycheck = argv.first == '-o'
    argv.shift if @onlycheck

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
        ['Presentation'].include?(event(e, 'event_subtype')) \
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
      abort "Error: The above talks have titles too long."
    end

    if @onlycheck
      @events = @events.each {
        |e|
        get_text event(e, 'event_key')
      }
    end
  end

  def run
    @dirs.each do |dr|
      File.directory?(dr) || abort("Is not a directory: #{dr}")

      puts "\n>> Directory: #{dr}"

      Dir.each_child dr do |vid|
        vid = File.join dr, vid

        ext = File.extname(vid)[1..]
      
        unless FMS.include? ext
          puts "Ignoring file: #{vid}"
          next
        end
        File.readable?(vid) || abort("File not readable: #{vid}")
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

    if is_done(ename)
      puts "Video already uploaded, skipping." unless @silent
      return
    end

    begin
      title, description = get_text ename
    rescue Exception
      return
    end

    verb "Uploading video, ID: #{ename}" if @silent

    out, err = ['', '']
    suc = local_execute \
      [ @ups,
        vid,
        title,
        description,
      ], 
      out: out,
      err: err,
      debug: @debug

    puts out unless out.empty?
    puts err unless err.empty?

    suc = false unless out.include?('was successfully uploaded')
    suc || abort("> FAILED")

    verb 'OK' + $/
    set_done ename
    sleep SLEEP
  end  

  def load_csv file
    file.nil? && abort("Arg missing.")
    File.readable?(file) || abort("Could not read: #{file}")
    CSV.read(file)
  end

  def acc whr, line, *keys
    x = keys.map {
      |key|
        i = whr[key]
        i.nil? && abort("Key not found: #{key}")
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

  def get_text ename
    eve = @events.detect {
      |e|
      event(e, 'event_key') == ename
    }
    eve.nil? && abort("Error: Event for video '#{ename}' not found.")

    name = event(eve, 'name')
    desc = event(eve, 'description')
    speakers = event(eve, 'speakers')

    lnk = @links.detect {
      |l|
      link(l, 'name') == name
    }
    lnk.nil? && abort("Error: Link for video not found.")
    shortlink = link(lnk, 'shortlink')

    title = sanitize(name + SUFFIX)
    description = sanitize <<EOD
Speakers: #{speakers}

#{desc}

[ #{shortlink} ]
#{FOOTER}
EOD

    if @debug
      puts " ================================================", ""
      verb "ID: #{ename}"
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
end

Upload.start(ARGV)
