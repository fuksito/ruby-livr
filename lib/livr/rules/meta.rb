module LIVR
  module Rules
    module Meta

      class NestedObject < Rule
        def initialize(livr)
          @validator = Validator.new(livr).prepare
        end

        def call(nested_object, user_data, field_results)
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
        def initialize(selector_field, livrs)
          @selector_field = selector_field
          @validators = {}
          livrs.each do |selector_value, livr|
            @validators[selector_value] = Validator.new(livr).prepare
          end
        end

        def call(object, user_data, field_results)
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
          livr = { field: rules.flatten }
          @validator = Validator.new(livr).prepare
        end

        def call(values, user_data, field_results)
          return if is_no_value(values)
          return 'FORMAT_ERROR' unless values.is_a?(Array)

          results = []
          errors = []
          has_errors = false

          values.each do |value|
            result = @validator.validate(field: value)

            if result
              results << result[:field]
              errors << nil
            else
              has_errors = true
              errors << @validator.get_errors[:field]
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

      class ListOfObjects < Rule
        def initialize(livr)
          @validator = Validator.new(livr).prepare
        end

        def call(objects, user_data, field_results)
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
        def initialize(selector_field, livrs)
          @selector_field = selector_field
          @validators = {}
          livrs.each do |selector_value, livr|
            @validators[selector_value] = Validator.new(livr).prepare
          end
        end

        def call(objects, user_data, field_results)
          return if is_no_value(objects)
          return 'FORMAT_ERROR' unless objects.is_a?(Array)

          results = []
          errors = []
          has_errors = false

          objects.each do |object|
            if !object.is_a?(Hash) || !object[@selector_field] || !@validators[ object[@selector_field] ]
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
          @validators = @rule_sets.map do |rules|
            livr = { field: rules }
            Validator.new(livr).prepare
          end
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)

          last_error = nil
          @validators.each do |validator|
            result = validator.validate(field: value)
            if result
              field_results << result[:field]
              return nil
            else
              last_error = validator.get_errors[:field]
            end
          end

          last_error ? last_error : nil
        end
      end

    end
  end
end

