require 'yaml'

module Sharry
  class Config
    def self.load_config
      @load_config ||= YAML.load_file(File.expand_path("../../config/config.yml", __dir__))
    end

    def self.get(key)
      load_config["default"][key.to_s]
    end
  end
end