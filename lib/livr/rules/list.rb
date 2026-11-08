module LIVR
  module Rules
    # LIVR 2.5
    module List

      # list_length(length), list_length(min, max) or list_length({"min" => ..., "max" => ...})
      class ListLength < Rule
        def initialize(*args)
          if args.first.is_a?(Hash)
            options = args.first.stringify_keys
            unknown = options.keys - %w[min max]
            raise "Rule [list_length] got an unknown option #{unknown.first.inspect}" if unknown.any?
            raise "Rule [list_length] got an empty object" if options.empty?

            @min = options.has_key?("min") ? count_argument(options["min"]) : 0
            @max = options.has_key?("max") ? count_argument(options["max"]) : Float::INFINITY
          else
            @min = count_argument(args[0])
            @max = args.size > 1 ? count_argument(args[1]) : @min
          end

          raise "Rule [list_length] takes a length, min and max, or an object with \"min\" and \"max\"" unless @min && @max
          raise "Rule [list_length] got \"min\" greater than \"max\"" if @min > @max
        end

        # An empty list is a value, not an empty value
        def call(list, user_data, field_results)
          return if is_no_value(list)
          return 'FORMAT_ERROR' unless list.is_a?(Array)

          return 'TOO_FEW_ITEMS' if list.size < @min
          return 'TOO_MANY_ITEMS' if list.size > @max
        end
      end

      # Without keys the items are primitive values, compared as strings. With keys the items are
      # objects, duplicates when all their key values are equal. Empty items are ignored
      class Unique < Rule
        def initialize(*keys)
          @keys = keys.map do |key|
            string_argument(key) or raise "Rule [unique] takes key names as strings, got #{key.inspect}"
          end
        end

        # One error for the whole list. A wrong item gives FORMAT_ERROR, even after duplicates
        def call(list, user_data, field_results)
          return if is_no_value(list)
          return 'FORMAT_ERROR' unless list.is_a?(Array)

          seen = {}
          has_duplicates = false

          list.each do |item|
            next if is_no_value(item)

            item_key = @keys.empty? ? primitive_key(item) : object_key(item)
            return 'FORMAT_ERROR' if item_key == :format_error
            next unless item_key

            has_duplicates = true if seen.has_key?(item_key)
            seen[item_key] = true
          end

          return 'NOT_UNIQUE_ITEMS' if has_duplicates
        end

        private

        def primitive_key(item)
          is_primitive(item) ? string_form(item) : :format_error
        end

        # The key values as strings, nil for an item with an empty key value
        def object_key(item)
          return :format_error unless item.is_a?(Hash)

          values = @keys.map { |key| item[key] }
          return :format_error if values.any? { |value| !is_no_value(value) && !is_primitive(value) }
          return if values.any? { |value| is_no_value(value) }

          values.map { |value| string_form(value) }
        end
      end

    end
  end
end
