require 'json'
require 'date'
require 'active_support/all'

require_relative "livr/validator.rb"
require_relative "livr/rule.rb"
require_relative "livr/aliased_rule.rb"
require_relative "livr/rules/common.rb"
require_relative "livr/rules/string.rb"
require_relative "livr/rules/numeric.rb"
require_relative "livr/rules/special.rb"
require_relative "livr/rules/modifiers.rb"
require_relative "livr/rules/meta.rb"

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

  Validator.register_default_rules(DEFAULT_RULES)
end