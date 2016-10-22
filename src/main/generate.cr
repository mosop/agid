module Agid::Main::Commands
  class Generate < Cli::Supercommand
  end
end

require "./generate/*"

class Agid::Main::Commands::Generate
  command "singulars"
  command "plurals"
end
