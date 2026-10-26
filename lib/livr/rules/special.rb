module LIVR
  module Rules
    module Special

      class Email < Rule
        # The same expression as in the reference implementation: one "@" only and no "_" in the domain.
        # [:space:] is Unicode-aware, like \s in JavaScript. \A and \z, not ^ and $: they match at line breaks.
        EMAIL_RE = /\A(?:[^<>()\[\]\\.,;:[:space:]@"]+(?:\.[^<>()\[\]\\.,;:[:space:]@"]+)*|"[^@\n\r\u2028\u2029]+")@(?:\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\]|(?:[a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,})\z/

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          return "WRONG_EMAIL" unless EMAIL_RE.match(value.to_s)
          return
        end
      end

      class EqualToField < Rule
        def initialize(field)
          @field = field
        end

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          # Compared as strings: "10" and 10 are equal. A missing field is not equal to any value.
          other_value = user_data[@field]
          return "FIELDS_NOT_EQUAL" unless is_primitive(other_value) && value.to_s == other_value.to_s
        end
      end

      class Url < Rule
        # \A and \z, not ^ and $: they match at line breaks in Ruby.
        URL_RE_STR = '\\A(?:(?:http|https)://)(?:\\S+(?::\\S*)?@)?(?:(?:(?:[1-9]\\d?|1\\d\\d|2[0-1]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[0-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))\\.?|localhost)(?::\\d{2,5})?(?:[/?#]\\S*)?\\z'
        URL_RE =  Regexp.compile(URL_RE_STR, "i")
        MAX_URL_LENGTH = 2083

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          if value.to_s.length < MAX_URL_LENGTH && URL_RE.match(value.to_s)
            return
          else
            'WRONG_URL'
          end
        end
      end

      class IsoDate < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = value.to_s
          return "WRONG_DATE" unless value.length == "YYYY-MM-DD".length

          date = Date.strptime(value, '%Y-%m-%d') rescue nil
          unless date
            return "WRONG_DATE"
          end
        end
      end

    end
  end
end