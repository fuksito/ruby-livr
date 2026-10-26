module LIVR
  class AliasedRule

    def initialize(_alias)
      raise "Alias name required" unless _alias["name"]
      raise "Alias rules required" unless _alias["rules"].present?

      @alias = _alias
    end

    # A rule for every use: each one gets the rules of the validator that uses it
    def new(*args)
      dup
    end

    def rule_builders=(rule_builders)
      @validator = Validator.new(value: Array.wrap(@alias["rules"])).register_rules(rule_builders).prepare
    end

    def call(value, user_data, field_results)
      self.rule_builders = {} unless @validator # built outside of a validator: default rules only
      # A missing value stays missing, unless the rules change it
      result = @validator.validate(value.nil? ? {} : { value: value })
      if result
        field_results << result[:value] if result.has_key?(:value)
        return
      else
        return @alias["error"] || @validator.get_errors[:value]
      end
    end
  end
end