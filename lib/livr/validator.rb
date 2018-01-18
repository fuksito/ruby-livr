module LIVR
  class Validator
    def initialize(rules, is_auto_trim=false)
      @rules = rules
      @is_prepared = false
      @validator_builders = {}
      @validators = {}
      @is_auto_trim = is_auto_trim

      register_default_rules
    end

    def self.register_default_rules(rules)
      @@default_rules ||= {}
      @@default_rules.merge!(rules.with_indifferent_access)
    end

    def register_aliased_rule(_alias)
      register_rules( _alias["name"] =>  AliasedRule.new(_alias) )
    end

    def prepare
      @rules.each do |field, field_rules|
        field_rules = Array.wrap(field_rules)
        @validators[field] = field_rules.map do |field_rule|
          rule_name, rule_args = parse_rule(field_rule)
          build_validator(rule_name, rule_args)
        end
        @is_prepared = true
      end
      self
    end

    def validate(user_data)
      prepare unless @is_prepared

      unless user_data.is_a?(Hash)
        @errors = 'FORMAT_ERROR'
        return
      end

      if @is_auto_trim
        user_data = auto_trim(user_data)
      end

      @result = {}
      @errors = {}

      @validators.each do |field, validators|
        next if validators.blank?
        next if !@rules.has_key?(field)

        value = user_data[field]
        validators.each do |validator|
          field_results = []
          field_value = @result.fetch(field, value)
          error_code = validator.call(field_value, user_data, field_results)

          if error_code
            @errors[field] = error_code
            break
          elsif field_results.present?
            @result[field] = field_results.first
          elsif user_data.has_key?(field) && !@result.has_key?(field)
            @result[field] = value
          end
        end
      end

      if @errors.present?
        return false
      else
        @errors = nil
        return @result
      end
    end

    def register_rules(rules)
      @validator_builders.merge!(rules)
      self
    end

    def get_errors
      @errors
    end

    private

    def register_default_rules
      register_rules(@@default_rules || [])
    end

    def parse_rule(livr_rule)
      name = nil
      args = nil

      case livr_rule
      when Hash
        name = livr_rule.keys.first
        args = Array.wrap(livr_rule[name])
      else
        name = livr_rule
        args = []
      end

      [ name, args ]
    end

    def build_validator(name, args)
      if @validator_builders[name].blank?
        raise "Rule ['#{name}'] not registered"
      end
      @validator_builders[name].new(*args)
    end

    private

    def auto_trim(user_data)
      case user_data
      when String
        user_data.strip
      when Array
        user_data.map{|v| auto_trim(v) }
      when Hash
        user_data.each do |key, value|
          user_data[key] = auto_trim(value)
        end
      else
        user_data
      end
    end

  end
end