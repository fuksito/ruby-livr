require 'json'
require 'date'
# activesupport 6.x uses Logger without loading it, which fails with concurrent-ruby 1.3.5 and later
require 'logger'
require 'active_support/all'

require_relative "livr/validator.rb"
require_relative "livr/rule.rb"
require_relative "livr/aliased_rule.rb"
require_relative "livr/reference.rb"
require_relative "livr/rules/common.rb"
require_relative "livr/rules/string.rb"
require_relative "livr/rules/numeric.rb"
require_relative "livr/rules/special.rb"
require_relative "livr/rules/modifiers.rb"
require_relative "livr/rules/meta.rb"
require_relative "livr/rules/list.rb"
require_relative "livr/rules/format.rb"
require_relative "livr/rules/checksum.rb"

module LIVR
  DEFAULT_RULES = {
    required:       Rules::Common::Required,
    not_empty:      Rules::Common::NotEmpty,
    not_empty_list: Rules::Common::NotEmptyList,
    any_object:     Rules::Common::AnyObject,

    string:         Rules::String::String,
    eq:             Rules::String::Eq,
    one_of:         Rules::String::OneOf,
    max_length:     Rules::String::MaxLength,
    min_length:     Rules::String::MinLength,
    length_equal:   Rules::String::LengthEqual,
    length_between: Rules::String::LengthBetween,
    like:           Rules::String::Like,

    integer:          Rules::Numeric::Integer,
    positive_integer: Rules::Numeric::PositiveInteger,
    decimal:          Rules::Numeric::Decimal,
    positive_decimal: Rules::Numeric::PositiveDecimal,
    max_number:       Rules::Numeric::MaxNumber,
    min_number:       Rules::Numeric::MinNumber,
    number_between:   Rules::Numeric::NumberBetween,

    email:          Rules::Special::Email,
    equal_to_field: Rules::Special::EqualToField,
    url:            Rules::Special::Url,
    iso_date:       Rules::Special::IsoDate,

    default:    Rules::Modifiers::Default,
    trim:       Rules::Modifiers::Trim,
    to_lc:      Rules::Modifiers::ToLc,
    to_uc:      Rules::Modifiers::ToUc,
    remove:     Rules::Modifiers::Remove,
    leave_only: Rules::Modifiers::LeaveOnly,

    nested_object:             Rules::Meta::NestedObject,
    variable_object:           Rules::Meta::VariableObject,
    list_of:                   Rules::Meta::ListOf,
    list_of_objects:           Rules::Meta::ListOfObjects,
    list_of_different_objects: Rules::Meta::ListOfDifferentObjects,
    or:                        Rules::Meta::Or,
  }.with_indifferent_access

  # Added in LIVR 2.5. {"rule" => nil} is one nil argument for them (a schema error), the rules
  # above and custom rules get no arguments, as in LIVR 2.0
  LIVR_2_5_RULES = {
    boolean:     Rules::Common::Boolean,
    any:         Rules::Common::Any,
    required_if: Rules::Common::RequiredIf,

    not_one_of:  Rules::String::NotOneOf,
    digits:      Rules::String::Digits,
    starts_with: Rules::String::StartsWith,
    ends_with:   Rules::String::EndsWith,
    contains:    Rules::String::Contains,

    max_decimals: Rules::Numeric::MaxDecimals,

    iso_datetime: Rules::Special::IsoDatetime,
    iso_time:     Rules::Special::IsoTime,

    split: Rules::Modifiers::Split,

    when:   Rules::Meta::When,
    values: Rules::Meta::Values,
    keys:   Rules::Meta::Keys,

    list_length: Rules::List::ListLength,
    unique:      Rules::List::Unique,

    uuid:      Rules::Format::Uuid,
    ip:        Rules::Format::Ip,
    cidr:      Rules::Format::Cidr,
    hostname:  Rules::Format::Hostname,
    base64:    Rules::Format::Base64,
    hex:       Rules::Format::Hex,
    digest:    Rules::Format::Digest,
    mongo_id:  Rules::Format::MongoId,
    hex_color: Rules::Format::HexColor,
    mac:       Rules::Format::Mac,
    e164:      Rules::Format::E164,
    semver:    Rules::Format::Semver,
    jwt:       Rules::Format::Jwt,

    luhn:        Rules::Checksum::Luhn,
    credit_card: Rules::Checksum::CreditCard,
    iban:        Rules::Checksum::Iban,
  }.with_indifferent_access

  DEFAULT_RULES.merge!(LIVR_2_5_RULES)

  Validator.register_default_rules(DEFAULT_RULES)
end