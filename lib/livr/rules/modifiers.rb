module LIVR
  module Rules
    module Modifiers
      class Default < Rule
        def initialize(default_value)
          @default_value = default_value
        end

        def call(value, user_data, field_results)
          if is_no_value(value)
            field_results << @default_value
          end
          return
        end
      end

      class Trim < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash)
          field_results << value.to_s.mb_chars.strip
          return
        end
      end

      class ToLc < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash)
          field_results << value.to_s.mb_chars.downcase
          return
        end
      end

      class ToUc < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash)
          field_results << value.to_s.mb_chars.upcase
          return
        end
      end

      class Remove < Rule
        def initialize(chars)
          @chars = chars
          @re = Regexp.compile("[#{Regexp.quote(@chars)}]")
        end

        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash)
          field_results << value.to_s.mb_chars.gsub(@re, '')
          return
        end
      end

      class LeaveOnly < Rule
        def initialize(chars)
          @chars = chars
          @re = Regexp.compile("[^#{Regexp.quote(@chars)}]")
        end

        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash)
          field_results << value.to_s.mb_chars.gsub(@re, '')
          return
        end
      end
    end
  end
end
