module LIVR
  module Rules
    module Numeric

      class Integer < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value_int = Integer(value.to_s) rescue nil
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

          value_int = Integer(value.to_s) rescue nil

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
        def initialize(max_number)
          @max_number = max_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = Float(value.to_s) rescue nil
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
        def initialize(min_number)
          @min_number = min_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = Float(value.to_s) rescue nil
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
        def initialize(min_number, max_number)
          @min_number = min_number
          @max_number = max_number
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = Float(value.to_s) rescue nil
          if value.nil?
            return "NOT_NUMBER"
          end


          return "TOO_LOW"  if value < @min_number
          return "TOO_HIGH" if value > @max_number

          field_results << value
          return
        end
      end

    end
  end
end