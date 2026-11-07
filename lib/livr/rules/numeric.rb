module LIVR
  module Rules
    module Numeric

      class Integer < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value_int = to_integer(value)
          if value_int.nil?
            return "NOT_INTEGER"
          end

          field_results << value_int
          return
        end
      end


      class PositiveInteger < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value_int = to_integer(value)

          return "NOT_POSITIVE_INTEGER" if value_int.nil?
          return "NOT_POSITIVE_INTEGER" unless value_int.positive?

          field_results << value_int
          return
        end
      end

      class Decimal < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value_int = Float(value.to_s) rescue nil
          return "NOT_DECIMAL" if value_int.nil?

          field_results << value_int
          return
        end
      end


      class PositiveDecimal < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value_float = Float(value.to_s) rescue nil
          return "NOT_POSITIVE_DECIMAL" if value_float.nil?
          return "NOT_POSITIVE_DECIMAL" unless value_float.positive?

          field_results << value_float
          return
        end
      end

      class MaxNumber < Rule
        def initialize(max_number, *)
          @max_number = max_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = to_number(value)
          if value.nil?
            return "NOT_NUMBER"
          end

          if value > @max_number
            return "TOO_HIGH"
          else
            field_results << value
            return
          end
        end
      end

      class MinNumber < Rule
        def initialize(min_number, *)
          @min_number = min_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = to_number(value)
          if value.nil?
            return "NOT_NUMBER"
          end

          if value < @min_number
            return "TOO_LOW"
          else
            field_results << value
            return
          end
        end
      end

      class NumberBetween < Rule
        def initialize(min_number, max_number, *)
          @min_number = min_number
          @max_number = max_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = to_number(value)
          if value.nil?
            return "NOT_NUMBER"
          end


          return "TOO_LOW"  if value < @min_number
          return "TOO_HIGH" if value > @max_number

          field_results << value
          return
        end
      end

      # LIVR 2.5: at most that many digits after the decimal point, without the trailing zeros
      class MaxDecimals < Rule
        DECIMAL_RE = /\A-?[0-9]+(?:\.([0-9]+))?\z/

        def initialize(*args)
          @max_decimals = count_argument(args.first)
          raise "Rule [max_decimals] takes a non-negative integer" unless @max_decimals
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' unless is_primitive(value)

          # A JSON number is counted in its string form (1e-3 has 3), a string as it is written
          # ("0.10000000000000000001" has 20). Not a finite double: the output is a number
          if value.is_a?(::String)
            match = DECIMAL_RE.match(value)
            return 'NOT_NUMBER' unless match && Float(value).finite?
            number = to_number(value)
            fraction = match[1]
          elsif value.is_a?(::Numeric) && value.to_f.finite?
            number = value
            fraction = string_form(value).split(".")[1]
          else
            return 'NOT_NUMBER'
          end

          return 'TOO_MANY_DECIMALS' if fraction.to_s.sub(/0+\z/, "").length > @max_decimals

          field_results << number
          return
        end
      end

    end
  end
end