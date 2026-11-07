module LIVR
  module Rules
    module Common

      class Required < Rule
        def call(value, user_data, field_results)
          "REQUIRED" if is_no_value(value)
        end
      end

      class NotEmpty < Rule
        def call(value, user_data, field_results)
          "CANNOT_BE_EMPTY" if value == ""
        end
      end

      class NotEmptyList < Rule
        def call(list, user_data, field_results)
          return "CANNOT_BE_EMPTY" if is_no_value(list)
          return "CANNOT_BE_EMPTY" if list.is_a?(Array) && list.blank?
          return "FORMAT_ERROR" unless list.is_a?(Array)
        end
      end

      class AnyObject < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return "FORMAT_ERROR" unless value.is_a?(Hash)
        end
      end

      # LIVR 2.5
      class Boolean < Rule
        TRUE_VALUES  = [true, 1, "1", "true"].freeze
        FALSE_VALUES = [false, 0, "0", "false"].freeze

        def initialize(*args)
          no_arguments("boolean", args)
        end

        # 1.0 is 1: 1.0 == 1 in Ruby
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return "FORMAT_ERROR" unless is_primitive(value)

          if TRUE_VALUES.include?(value)
            field_results << true
          elsif FALSE_VALUES.include?(value)
            field_results << false
          else
            return "NOT_BOOLEAN"
          end
          return
        end
      end

      # LIVR 2.5: any value passes unchanged, objects and lists too
      class Any < Rule
        def initialize(*args)
          no_arguments("any", args)
        end

        def call(value, user_data, field_results)
        end
      end

      # LIVR 2.5: {"required_if" => {"type" => "company", "address/country" => ["UA", "PL"]}}.
      # The field is required when every referenced value is a non-empty primitive value equal to
      # the given value, or to one of the listed values, compared as strings
      class RequiredIf < Rule
        def initialize(*args)
          conditions = args.first
          unless conditions.is_a?(Hash) && conditions.present?
            raise "Rule [required_if] takes an object of references to values"
          end

          @conditions = conditions.map do |reference, expected|
            expected_values = expected.is_a?(Array) ? expected : [expected]
            # "" and [] never match: an empty referenced value is never a match
            if expected_values.empty? || !expected_values.all? { |v| is_primitive(v) && v != "" }
              raise "Rule [required_if] takes a primitive value other than \"\" or a list of them for #{reference.inspect}"
            end

            [Reference.parse(reference, "required_if"), expected_values.map { |v| string_form(v) }]
          end
        end

        def call(value, user_data, field_results)
          return unless is_no_value(value)

          is_required = @conditions.all? do |path, expected_values|
            ref_value = Reference.resolve(user_data, path)
            is_primitive(ref_value) && ref_value != "" && expected_values.include?(string_form(ref_value))
          end

          "REQUIRED" if is_required
        end
      end

    end
  end
end