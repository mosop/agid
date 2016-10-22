require "../../agid"

module Agid::Main::Commands::Generate::Commands
  class Plurals < Cli::Command
    class Options
      arg "language", required: true
      arg "module_name", required: true
      help
    end

    SUMMARY = {} of String => Int32

    PATTERNS = [
      /hes$/,
      /oes$/,
      /ses$/,
      /xes$/,
      /zes$/,
      /men$/,
      /ies$/,
    ]

    def puts_summary
      SUMMARY.keys.sort.each do |cuttail|
        next if SUMMARY[cuttail] < 50
        puts "#{cuttail.ljust(15)}: #{SUMMARY[cuttail]}"
      end
    end

    def diff(singular, plural, substring = nil)
      substring ||= plural
      raise "unmatched forms: #{singular} #{plural}" if substring.size == 0
      if singular.starts_with?(substring)
        {cut: plural.size - substring.size, tail: singular[(substring.size)..-1]}
      else
        diff(singular, plural, substring[0..-2])
      end
    end

    @result_io : IO?
    def result_io
      @result_io ||= STDOUT
    end

    def inspect_diff(diff)
      case args.language
      when "crystal"
        diff.inspect
      when "ruby"
        "[#{diff[:cut]}, #{diff[:tail].inspect}]"
      else
        raise "Unknown language: #{args.language}"
      end
    end

    def run
      result_io.puts <<-EOS
        module #{args.module_name}
          @@plurals = {
        EOS

      Agid.plurals_singulars.each do |plural, singular|
        diff = diff(singular, plural)
        if diff[:cut] == 1 && diff[:tail] == ""
          if PATTERNS.all?{|i| i !~ plural}
            SUMMARY["-"] ||= 0
            SUMMARY["-"] += 1
            next
          end
        elsif diff[:cut] == 1 && diff[:tail] == "um"
          cuttail = "1  um!#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
        elsif diff[:cut] == 1 && diff[:tail] == "us"
          cuttail = "1  us!#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
        elsif diff[:cut] == 2 && diff[:tail] == ""
          cuttail = "2  !#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          next if (/hes$/ =~ plural)
          next if (/oes$/ =~ plural)
          next if (/ses$/ =~ plural)
          next if (/xes$/ =~ plural)
          next if (/zes$/ =~ plural)
        elsif diff[:cut] == 2 && diff[:tail] == "an"
          cuttail = "2  an!#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          next if (/men$/ =~ plural)
        elsif diff[:cut] == 2 && diff[:tail] == "is"
          cuttail = "2  is!#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          # next if (/ses$/ =~ plural)
        elsif diff[:cut] == 3 && diff[:tail] == "y"
          cuttail = "3  y!#{plural[(-[plural.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          next if (/ies$/ =~ plural)
        end
        cuttail = "#{diff[:cut].to_s.ljust(2)} #{diff[:tail]}"
        SUMMARY[cuttail] ||= 0
        SUMMARY[cuttail] += 1
        result_io.puts <<-EOS
            "#{plural}" => #{inspect_diff(diff)},
        EOS
      end

      result_io.puts <<-EOS
        }
        def self.plurals
          @@plurals
        end
      end
      EOS
    end
  end
end
