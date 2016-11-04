require "cli"
require "crystal_plus/named_tuple/#merge"
require "./agid"

module Agid
  class Main < Cli::Supercommand
    command_name "agid"
  end
end

require "./main/*"

class Agid::Main
  command "generate"
end

Agid::Main.run ARGV
