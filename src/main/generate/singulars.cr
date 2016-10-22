require "../../agid"

module Agid::Main::Commands::Generate::Commands
  class Singulars < Cli::Command
    class Options
      arg "language", required: true
      arg "module_name", required: true
      help
    end

    SUMMARY = {} of String => Int32

    PATTERNS = [
      # /h$/,
      # /o$/,
      /s$/,
      /x$/,
      /z$/,
      /y$/,
      # /on$/,
      # /am$/,
      /man$/,
      # /is$/,
    ]

    def puts_summary
      SUMMARY.keys.sort.each do |cuttail|
        next if SUMMARY[cuttail] < 50
        puts "#{cuttail.ljust(15)}: #{SUMMARY[cuttail]}"
      end
    end

    def diff(singular, plural, substring = nil)
      substring ||= singular
      raise "unmatched forms: #{singular} #{plural}" if substring.size == 0
      if plural.starts_with?(substring)
        {cut: singular.size - substring.size, tail: plural[(substring.size)..-1]}
      else
        diff(singular, plural, substring[0..-2])
      end
    end

    @result_io : IO
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

    @result_io : IO?
    def result_io
      @result_io ||= STDOUT
    end

    def run
      result_io.puts <<-EOS
      module #{args.module_name}
        @@singulars = {
      EOS

      Agid.singulars_plurals.each do |singular, plural|
        diff = diff(singular, plural)
        if diff[:cut] == 0 && diff[:tail] == "s"
          if PATTERNS.all?{|i| i !~ singular}
            SUMMARY["-"] ||= 0
            SUMMARY["-"] += 1
            next
          end
        elsif diff[:cut] == 0 && diff[:tail] == "es"
          cuttail = "0  es!#{singular[(-[singular.size, 1].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          # next if (/h$/ =~ singular)
          # next if (/o$/ =~ singular)
          next if (/s$/ =~ singular)
          next if (/x$/ =~ singular)
          next if (/z$/ =~ singular)
        elsif diff[:cut] == 1 && diff[:tail] == "ies"
          cuttail = "1  ies!#{singular[(-[singular.size, 1].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          next if (/y$/ =~ singular)
        elsif diff[:cut] == 2 && diff[:tail] == "a"
          cuttail = "2  a!#{singular[(-[singular.size, 2].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          # next if (/on$/ =~ singular)
          # next if (/am$/ =~ singular)
        elsif diff[:cut] == 2 && diff[:tail] == "en"
          cuttail = "2  en!#{singular[(-[singular.size, 3].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          next if (/man$/ =~ singular)
        elsif diff[:cut] == 2 && diff[:tail] == "es"
          cuttail = "2  es!#{singular[(-[singular.size, 2].min)..-1]}"
          SUMMARY[cuttail] ||= 0
          SUMMARY[cuttail] += 1
          # next if (/is$/ =~ singular)
        end
        cuttail = "#{diff[:cut].to_s.ljust(2)} #{diff[:tail]}"
        SUMMARY[cuttail] ||= 0
        SUMMARY[cuttail] += 1
        result_io.puts <<-EOS
            "#{singular}" => #{inspect_diff(diff)},
        EOS
      end

      result_io.puts <<-EOS
        }
        def self.singulars
          @@singulars
        end
      end
      EOS
    end
  end
end
