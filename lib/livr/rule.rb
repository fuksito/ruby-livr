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
  end
end