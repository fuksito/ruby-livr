module LIVR
  module Rules
    module Common

      class Required < Rule
        def call(value, user_data, field_results)
          return if value.in?([[], {}])
          "REQUIRED" if value.blank?
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

    end
  end
end