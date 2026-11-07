module LIVR
  module Rules
    # LIVR 2.5. The string form is checked as it is: no spaces, dashes or lowercase letters are
    # removed. A boolean gives the error code of the rule, like in format rules
    module Checksum

      def self.luhn?(digits)
        sum = 0
        digits.reverse.each_char.with_index do |char, index|
          digit = char.to_i
          if index.odd?
            digit *= 2
            digit -= 9 if digit > 9
          end
          sum += digit
        end
        sum % 10 == 0
      end

      class Luhn < Format::FormatRule
        def initialize(*args)
          no_arguments("luhn", args)
        end

        def error_code
          'WRONG_CHECKSUM'
        end

        def valid?(value)
          value.match?(/\A[0-9]{2,}\z/) && Checksum.luhn?(value)
        end
      end

      # 12-19 digits (ISO/IEC 7812) and the Luhn checksum, no card network detection
      class CreditCard < Format::FormatRule
        def initialize(*args)
          no_arguments("credit_card", args)
        end

        def error_code
          'WRONG_CREDIT_CARD_NUMBER'
        end

        def valid?(value)
          value.match?(/\A[0-9]{12,19}\z/) && Checksum.luhn?(value)
        end
      end

      # ISO 13616 without a per-country length table: the first four characters moved to the end,
      # letters replaced by numbers (A = 10 ... Z = 35), the number modulo 97 is 1
      class Iban < Format::FormatRule
        def initialize(*args)
          no_arguments("iban", args)
        end

        def error_code
          'WRONG_IBAN'
        end

        def valid?(value)
          return false unless value.match?(/\A[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}\z/)

          (value[4..-1] + value[0, 4]).gsub(/[A-Z]/) { |letter| (letter.ord - 55).to_s }.to_i % 97 == 1
        end
      end

    end
  end
end
