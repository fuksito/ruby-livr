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
          regexp = Regexp.compile(whole_value_anchors(@re_str), @flags)

          unless regexp.match(value)
            return 'WRONG_FORMAT'
          end

          field_results << value

          return
        end

        private

        # LIVR patterns follow JavaScript, where ^ and $ anchor the whole value. In Ruby
        # they anchor any line, so "12345\n<script>" would match "^[0-9]{5}$".
        # Replaces ^ and $ outside character classes with \A and \z.
        def whole_value_anchors(re_str)
          result = +""
          class_depth = 0
          chars = re_str.to_s.chars
          i = 0

          while i < chars.size
            char = chars[i]

            if char == "\\"
              result << char << chars[i + 1].to_s
              i += 2
              next
            end

            if class_depth > 0
              class_depth += 1 if char == "["
              class_depth -= 1 if char == "]"
              result << char
            elsif char == "["
              class_depth = 1
              result << char
              # "]" right after "[" or "[^" is a literal, not the end of the class
              if chars[i + 1] == "^"
                result << chars[i + 1]
                i += 1
              end
              if chars[i + 1] == "]"
                result << chars[i + 1]
                i += 1
              end
            elsif char == "^"
              result << "\\A"
            elsif char == "$"
              result << "\\z"
            else
              result << char
            end

            i += 1
          end

          result
        end
      end

    end
  end
end