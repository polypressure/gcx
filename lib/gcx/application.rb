#
# Entry point for the command-line application. Parses any options on the
# command-line, and either reads the files provided in the command-line
# arguments (if any), or directly from STDIN, delegating to the Command
# object to actually process each line.
#
module GCX

  class Application

    #
    # Initialize with the command-line args and options.
    #
    def initialize(argv)
      @options, @file_list = parse_options(argv)
      Command.configure(@options)
    end

    #
    # Start me up...
    #
    def run
      start_progress_bar
      if @file_list.empty?
        process(STDIN)
      else
        process_file_list(@file_list)
      end

      # Print the summary report. Not memory-efficient
      # for larg inputs obviously.
      puts Account.summary
    end


    private

    #
    #
    def start_progress_bar
      return unless @options[:progress_bar]
      @progress_bar = ProgressBar.create(
        total: count = line_count(@file_list),
        output: STDERR,
        format: count ? "%t: %p%%|%B" : "Working [%a] %B"
      )
    end

    def increment_progress_bar
      @progress_bar.increment if @progress_bar
    end

    #
    # Process an individual file or stdio.
    #
    def process(lines, filename="stdio")
      line_number = 1
      lines.each_line do |line|
        Command.process(line, filename, line_number)
        line_number += 1
        increment_progress_bar
      end
    end

    #
    # Process a list of files.
    #
    def process_file_list(file_list)
      file_list.each do |filename|
        File.open(filename) { |f| process(f, filename) }
      end
    end

    def parse_options(argv)
      params = { abort_on_error: false, progress_bar: false }
      parser = OptionParser.new

      parser.on("-a") { params[:abort_on_error] = true }
      parser.on("-p") { params[:progress_bar] = true }

      files = parser.parse(argv)

      [params, files]
    end

    def line_count(file_list)
      file_list.empty? ?
        nil :
        %x{wc -l #{file_list.join(' ')} | awk 'END {print $1}'}.to_i
    end
  end
end
