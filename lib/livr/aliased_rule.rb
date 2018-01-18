module LIVR
  class AliasedRule

    def initialize(_alias)
      raise "Alias name required" unless _alias["name"]
      raise "Alias rules required" unless _alias["rules"].present?

      @alias = _alias
      @validator = Validator.new(value: Array.wrap(@alias["rules"]))
    end

    def new(*args)
      self
    end

    def call(value, user_data, field_results)
      result = @validator.validate({ value: value })
      if result
        field_results << result[:value]
        return
      else
        return @alias.fetch("error", @validator.get_errors)
      end
    end
  end
end