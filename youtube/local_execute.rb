require 'shellwords'
require 'open3'

module LocalExecute
  # call-seq:
  #   local_execute(command, debug: false, out: '', err: '', work_dir: '') -> true or false
  #   local_execute(string, debug: false, out: '', err: '', work_dir: '')  -> true or false
  #   local_execute(array, debug: false, out: '', err: '', work_dir: '')   -> true or false
  #
  # Execute +command+ in the system shell, append the +out+ with
  # command's output and append +err+ with command's error output,
  # execute the command in +work_dir+ if specified.
  #
  # +command+ command to execute. String is expected to be already
  # correctly formatted for shell.
  #
  # +debug+ verbose output if set to true
  #
  # +out+ appends command's standard output to passed object
  #
  # +err+ appends command's error output to passed object
  #
  # +work_dir+ change the directory to where the command will be executed
  #
  # If command's exitstatus is 0 then returns true otherwise false.
  #
  # Example:
  #
  #   class Foo
  #     include LocalExecute
  #   end
  #
  #   foo = Foo.new
  #   foo.local_execute ['echo', 'hello'] #=> true
  #
  #   command_output = ''
  #   foo.local_execute('echo hello', out: command_output) #=> true
  #   command_output #=> 'hello'
  def local_execute(command, debug: false, out: '', err: '', input: '',work_dir: '.')
    escaped_command = command.respond_to?(:join) ? Shellwords.join(command) : command

    cmd_out, cmd_err, status = Open3.capture3(escaped_command, chdir: work_dir, stdin_data: input)
    out << cmd_out
    err << cmd_err
    if debug
      $stderr.puts "+ #{escaped_command}",
        "out: #{cmd_out}",
        "err: #{cmd_err}",
        "result: #{status}"
    end
    status.exitstatus.eql?(0)
  end
end
