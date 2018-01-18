module LIVR
  module Rules
    module Special

      class Email < Rule
        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          value = value.to_s
          email_re = /^([\w\-_+]+(?:\.[\w\-_+]+)*)@((?:[\w\-]+\.)*\w[\w\-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
          return "WRONG_EMAIL" unless email_re.match(value)
          return "WRONG_EMAIL" if  /\@.*\@/.match(value)
          return "WRONG_EMAIL" if /\@.*_/.match(value)
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

          return "FIELDS_NOT_EQUAL" if value != user_data[@field]
        end
      end

      class Url < Rule
        URL_RE_STR = '^(?:(?:http|https)://)(?:\\S+(?::\\S*)?@)?(?:(?:(?:[1-9]\\d?|1\\d\\d|2[0-1]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[0-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))\\.?|localhost)(?::\\d{2,5})?(?:[/?#]\\S*)?$'
        URL_RE =  Regexp.compile(URL_RE_STR, "i")
        MAX_URL_LENGTH = 2083

        def call(value, user_data, field_results)
          return if is_no_value(value)
          return 'FORMAT_ERROR' if !is_primitive(value)

          if value.length < MAX_URL_LENGTH && URL_RE.match(value)
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