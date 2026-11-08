module LIVR
  class Rule

    def initialize(*)
    end

    def call(value, user_data, field_results)
      raise NotImplementedError
    end

    private

    def is_primitive(value)
      [Numeric, String, TrueClass, FalseClass].any?{|klass| value.is_a?(klass) }
    end

    def is_no_value(value)
      value == nil || value == ""
    end

    # Base 10: Integer() alone reads "010" as an octal and "0x10" as a hexadecimal number.
    # No underscores: Integer() and Float() read "1_000" as 1000, like a Ruby literal.
    def to_integer(value)
      return if value.to_s.include?("_")
      Integer(value.to_s, 10) rescue nil
    end

    # Integers stay integers: "10" is 10, "1.5" is 1.5
    def to_number(value)
      return if value.to_s.include?("_")
      to_integer(value) || (Float(value.to_s) rescue nil)
    end

    # LIVR 2.5: the string form of a primitive value, the text that rules check and compare.
    # Integral numbers have no decimal point (1.0 is "1", 1.0.to_s is "1.0"), other numbers no
    # exponent (0.00001 is "0.00001", 0.00001.to_s is "1.0e-05")
    def string_form(value)
      return value if value.is_a?(::String)
      return value.to_s unless value.is_a?(Float) && value.finite?
      return value.to_i.to_s if value == value.truncate

      string = value.abs.to_s
      return value.to_s unless string.include?("e")

      # Floats below 0.0001: "1.5e-05" is "0.000015"
      mantissa, exponent = string.split("e")
      integer_part, fraction = mantissa.split(".")
      digits = (integer_part + fraction).sub(/0+\z/, "")
      "#{'-' if value < 0}0.#{'0' * (-exponent.to_i - integer_part.length)}#{digits}"
    end

    # LIVR 2.5: a rule that takes no arguments rejects any. An argument that looks like
    # a restriction must not be ignored
    def no_arguments(rule_name, args)
      raise "Rule [#{rule_name}] takes no arguments" unless args.empty?
    end

    # LIVR 2.5: the rules of when, values and keys. null and [] in place of rules are schema
    # errors, also inside a list of rules (["required", []]): use "any" for no rules
    def check_rules(rule_name, rules)
      if rules.nil? || rules == []
        raise "Rule [#{rule_name}] got #{rules.inspect} as rules, use \"any\" for no rules"
      end
      rules.each { |rule| check_rules(rule_name, rule) } if rules.is_a?(Array)
    end

    # LIVR 2.5 arguments: a number where a rule takes a string is its string form
    # ({"split" => 1} splits at "1"). nil for any other value
    def string_argument(value)
      string_form(value) if value.is_a?(::String) || value.is_a?(Numeric)
    end

    # LIVR 2.5 arguments: a non-negative integer, or a string with it in the grammar of the
    # "decimal" rule ({"max_decimals" => "2"}, "2.0", "02"; not " 2", "1e1" or "0x40").
    # nil for any other value
    def count_argument(value)
      value = Float(value) if value.is_a?(::String) && value.match?(/\A-?[0-9]+(\.[0-9]+)?\z/)
      value = value.to_i if value.is_a?(Float) && value.finite? && value == value.truncate
      value if value.is_a?(::Integer) && value >= 0
    end
  end
end