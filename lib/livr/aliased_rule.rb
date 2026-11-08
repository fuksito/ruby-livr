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
      # Aliases are transparent: their rules see the fields next to the field that uses the alias
      error_code = @validator.validate_field(:value, value, user_data, field_results)
      @alias["error"] || error_code if error_code
    end
  end
end