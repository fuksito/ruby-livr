module LIVR
  module Rules
    module Modifiers
      class Default < Rule
        def initialize(default_value, *)
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
          return if is_no_value(value) || value.is_a?(Hash) || value.is_a?(Array)
          field_results << value.to_s.strip
          return
        end
      end

      class ToLc < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash) || value.is_a?(Array)
          field_results << value.to_s.downcase
          return
        end
      end

      class ToUc < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash) || value.is_a?(Array)
          field_results << value.to_s.upcase
          return
        end
      end

      class Remove < Rule
        def initialize(chars, *)
          @chars = chars
          @re = Regexp.compile("[#{Regexp.quote(@chars)}]")
        end

        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash) || value.is_a?(Array)
          field_results << value.to_s.gsub(@re, '')
          return
        end
      end

      class LeaveOnly < Rule
        def initialize(chars, *)
          @chars = chars
          @re = Regexp.compile("[^#{Regexp.quote(@chars)}]")
        end

        def call(value, user_data, field_results)
          return if is_no_value(value) || value.is_a?(Hash) || value.is_a?(Array)
          field_results << value.to_s.gsub(@re, '')
          return
        end
      end

      # LIVR 2.5: a string, a number or a boolean becomes a list of the parts between the separators
      class Split < Rule
        def initialize(*args)
          separator = string_argument(args.first)
          raise "Rule [split] takes a non-empty separator string" if separator.to_s.empty?
          # A regular expression: String#split with " " splits at any whitespace
          @re = Regexp.compile(Regexp.quote(separator))
        end

        # A list stays as it is, an empty value and an object too: the next rule reports them
        def call(value, user_data, field_results)
          return if is_no_value(value) || !is_primitive(value)
          # -1: empty parts are kept, "a,," is ["a", "", ""]
          field_results << string_form(value).split(@re, -1)
          return
        end
      end
    end
  end
end
