module LIVR
  module Rules
    module Meta
      # The fields that the rules of a list item, an object value or a key see: none
      NO_FIELDS = {}.freeze

      class NestedObject < Rule
        def initialize(livr, *)
          @livr = livr
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        def call(nested_object, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          return if is_no_value(nested_object)
          return 'FORMAT_ERROR' unless nested_object.is_a?(Hash)

          result = @validator.validate(nested_object)

          if result
            field_results << result
            return
          else
            return @validator.get_errors
          end
        end
      end

      class VariableObject < Rule
        def initialize(selector_field, livrs, *)
          @selector_field = selector_field
          @livrs = livrs
        end

        def rule_builders=(rule_builders)
          @validators = {}
          @livrs.each do |selector_value, livr|
            @validators[selector_value] = Validator.new(livr).register_rules(rule_builders).prepare
          end
        end

        def call(object, user_data, field_results)
          self.rule_builders = {} unless @validators # built outside of a validator: default rules only
          return if is_no_value(object)
          if ( !object.is_a?(Hash) || !object[@selector_field] || !@validators[ object[@selector_field] ] )
            return 'FORMAT_ERROR'
          end

          validator = @validators.fetch(object.fetch(@selector_field))
          result = validator.validate(object)

          if result
            field_results << result
            return
          else
            return validator.get_errors
          end
        end
      end

      class ListOf < Rule
        def initialize(*rules)
          @livr = { field: rules.flatten }
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        def call(values, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          return if is_no_value(values)
          return 'FORMAT_ERROR' unless values.is_a?(Array)

          results = []
          errors = []
          has_errors = false

          values.each do |value|
            # Items have no containing object: a field reference in their rules is a missing value
            value_results = []
            error_code = @validator.validate_field(:field, value, NO_FIELDS, value_results)

            if error_code
              has_errors = true
              errors << error_code
              results << nil
            else
              results << value_results.first
              errors << nil
            end
          end

          if has_errors
            return errors
          else
            field_results << results
            return
          end
        end
      end

      class ListOfObjects < Rule
        def initialize(livr, *)
          @livr = livr
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        def call(objects, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          return if is_no_value(objects)
          return 'FORMAT_ERROR' unless objects.is_a?(Array)

          results = []
          errors = []
          has_errors = false

          objects.each do |object|
            result = @validator.validate(object)

            if result
              results << result
              errors << nil
            else
              has_errors = true
              errors << @validator.get_errors
              results << nil
            end
          end

          if has_errors
            return errors
          else
            field_results << results
            return
          end

        end
      end

      class ListOfDifferentObjects < Rule
        def initialize(selector_field, livrs, *)
          @selector_field = selector_field
          @livrs = livrs
        end

        def rule_builders=(rule_builders)
          @validators = {}
          @livrs.each do |selector_value, livr|
            @validators[selector_value] = Validator.new(livr).register_rules(rule_builders).prepare
          end
        end

        def call(objects, user_data, field_results)
          self.rule_builders = {} unless @validators # built outside of a validator: default rules only
          return if is_no_value(objects)
          return 'FORMAT_ERROR' unless objects.is_a?(Array)

          results = []
          errors = []
          has_errors = false

          objects.each do |object|
            if !object.is_a?(Hash) || !object[@selector_field] || !@validators[ object[@selector_field] ]
              has_errors = true
              errors << 'FORMAT_ERROR'
              next
            end

            validator = @validators[ object[@selector_field] ]
            result = validator.validate(object)

            if result
              results << result
              errors << nil
            else
              has_errors = true
              errors << validator.get_errors
              results << nil
            end
          end

          if has_errors
            return errors
          else
            field_results << results
            return
          end
        end
      end


      class Or < Rule
        def initialize(*rule_sets)
          @rule_sets = rule_sets
        end

        def rule_builders=(rule_builders)
          @validators = @rule_sets.map do |rules|
            livr = { field: rules }
            Validator.new(livr).register_rules(rule_builders).prepare
          end
        end

        def call(value, user_data, field_results)
          self.rule_builders = {} unless @validators # built outside of a validator: default rules only
          # Empty and missing values go to the rule sets too ("required" can be one of them).
          # A missing value stays missing, unless a rule set changes it. The rule sets are
          # transparent: their rules see the fields next to the field
          last_error = nil
          @validators.each do |validator|
            results = []
            last_error = validator.validate_field(:field, value, user_data, results)
            unless last_error
              field_results.concat(results)
              return nil
            end
          end

          last_error ? last_error : nil
        end
      end

      # LIVR 2.5. The condition form: when(reference, condition, rules_if_true, [rules_if_false]),
      # the switch form: when(reference, cases). Arguments after the 4th are ignored
      class When < Rule
        def initialize(*args)
          raise "Rule [when] takes a reference and cases, or a reference, a condition and rules" if args.size < 2

          @path = Reference.parse(args[0], "when")

          if args.size == 2
            cases = args[1]
            raise "Rule [when] takes cases as an object of values to rules" unless cases.is_a?(Hash)
            raise "Rule [when] got no cases" if cases.empty?

            # Fields of the validator of the rules: the case values as strings
            @livr = cases.transform_keys(&:to_s)
            @is_switch = true
          else
            @livr = { condition: args[1], if_true: args[2] }
            @livr[:if_false] = args[3] if args.size > 3
          end

          @livr.each_value { |rules| check_rules("when", rules) }
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        # The rules of the condition and the branches see the fields next to the field
        def call(value, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          ref_value = Reference.resolve(user_data, @path)

          if @is_switch
            # An empty or unknown referenced value chooses no case: an empty value passes
            # unchanged (the referenced field reports its own errors), any other value would pass unchecked
            branch = string_form(ref_value) if is_primitive(ref_value) && ref_value != ""
            unless @livr.has_key?(branch)
              return is_no_value(value) ? nil : "NOT_ALLOWED_VALUE"
            end
          else
            # The output of the condition is discarded
            is_true = !is_no_value(ref_value) && !@validator.validate_field(:condition, ref_value, user_data, [])
            branch = is_true ? :if_true : :if_false
            return unless @livr.has_key?(branch) # no rules if false: the value passes unchanged
          end

          @validator.validate_field(branch, value, user_data, field_results)
        end
      end

      # LIVR 2.5: every value of an object is validated with the rules, as list_of validates every item
      class Values < Rule
        def initialize(*rules)
          check_rules("values", rules)
          @livr = { field: rules.flatten }
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        def call(object, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          return if is_no_value(object)
          return 'FORMAT_ERROR' unless object.is_a?(Hash)

          result = {}
          errors = {}

          object.each do |key, value|
            value_results = []
            error_code = @validator.validate_field(:field, value, NO_FIELDS, value_results)

            if error_code
              errors[key] = error_code
            else
              result[key] = value_results.empty? ? value : value_results.first
            end
          end

          return errors if errors.present?
          field_results << result
          return
        end
      end

      # LIVR 2.5: every key of an object is validated as a string with the rules. The rules only check
      class Keys < Rule
        def initialize(*rules)
          check_rules("keys", rules)
          @livr = { field: rules.flatten }
        end

        def rule_builders=(rule_builders)
          @validator = Validator.new(@livr).register_rules(rule_builders).prepare
        end

        def call(object, user_data, field_results)
          self.rule_builders = {} unless @validator # built outside of a validator: default rules only
          return if is_no_value(object)
          return 'FORMAT_ERROR' unless object.is_a?(Hash)

          errors = {}
          object.each_key do |key|
            errors[key] = 'WRONG_KEY' if @validator.validate_field(:field, key.to_s, NO_FIELDS, [])
          end

          return errors if errors.present?
        end
      end

    end
  end
end

