module LIVR
  module Rules
    module String

      class String < Rule
        def call(value, user_data, field_results)
          return if value.in? [nil, ""]
          return 'FORMAT_ERROR' unless is_primitive(value)

          field_results << value.to_s

          return nil
        end
      end

      class Eq < Rule
        def initialize(allowed_value)
          @allowed_value = allowed_value
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' unless is_primitive(value)

          if value.to_s == @allowed_value.to_s
            field_results << @allowed_value
            return
          end

          return 'NOT_ALLOWED_VALUE'
        end
      end

      class OneOf < Rule
        def initialize(*allowed_values)
          @allowed_values = allowed_values.flatten
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' unless is_primitive(value)

          @allowed_values.each do |allowed_value|
            if allowed_value.to_s == value.to_s
              field_results << allowed_value
              return
            end
          end

          return 'NOT_ALLOWED_VALUE'
        end
      end

      class MaxLength < Rule
        def initialize(max_length)
          @max_length = max_length
        end

        def call(value, user_data, field_results)
          return if value.in? [nil, ""]
          return 'FORMAT_ERROR' unless is_primitive(value)

          return 'TOO_LONG' if value.to_s.length > @max_length
          field_results << value.to_s
          return
        end
      end

      class MinLength < Rule
        def initialize(min_length)
          @min_length = min_length
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' unless is_primitive(value)
          if value.to_s.length < @min_length
            return 'TOO_SHORT'
          end

          field_results << value.to_s
          return
        end
      end

      class LengthEqual < Rule
        def initialize(length)
          @length = length
        end

        def call(value, user_data, field_results)
          return if value.in? [nil, ""]
          return 'FORMAT_ERROR' unless is_primitive(value)

          value = value.to_s
          return 'TOO_SHORT' if value.length < @length
          return 'TOO_LONG'  if value.length > @length

          field_results << value

          return
        end
      end

      class LengthBetween < Rule
        def initialize(min_length, max_length)
          @min_length = min_length
          @max_length = max_length
        end

        def call(value, user_data, field_results)
          return if value.in? [nil, ""]
          return 'FORMAT_ERROR' unless is_primitive(value)

          value = value.to_s
          return 'TOO_SHORT' if value.length < @min_length
          return 'TOO_LONG'  if value.length > @max_length

          field_results << value

          return
        end
      end

      class Like < Rule
        def initialize(re_str, flags=nil)
          @re_str = re_str
          @flags = flags
        end

        def call(value, user_data, field_results)
          return if value.in? [nil, ""]
          return 'FORMAT_ERROR' unless is_primitive(value)

          value = value.to_s
          regexp = Regexp.compile(@re_str, @flags)

          unless regexp.match(value)
            return 'WRONG_FORMAT'
          end

          field_results << value

          return
        end
      end

    end
  end
end