module DatabaseSlave
  def self.configurations
    Configuration.new.config
  end

  # TODO 错误检查, 边界条件检查
  class Configuration
    attr_reader :config

    def initialize(*)
      @config = database_configuration[Rails.env]
    end

    private

    def database_configuration
      require 'erb'
      YAML::load(ERB.new(IO.read("#{Rails.root}/config/shards.yml")).result)
    end
  end
end
