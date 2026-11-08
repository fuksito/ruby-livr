[![test](https://github.com/fuksito/ruby-livr/actions/workflows/test.yml/badge.svg)](https://github.com/fuksito/ruby-livr/actions/workflows/test.yml)

# LIVR Validator
LIVR.Validator - Lightweight validator supporting Language Independent Validation Rules Specification (LIVR)
Implements latest ['2.5 specification'](http://livr-spec.org) (see [LIVR 2.5 rules](#livr-25-rules) below)

# SYNOPSIS
Common usage:

```ruby
gem 'ruby-livr'
require 'livr'

validator = LIVR::Validator.new({
    'name'      => 'required',
    'email'     => [ 'required', 'email' ],
    'gender'    => { 'one_of' => ['male', 'female'] },
    'phone'     => { 'max_length' => 10 },
    'password'  => [ 'required', { 'min_length' => 10} ],
    'password2' => { 'equal_to_field' => 'password' }
});

valid_data = validator.validate(user_data)

if valid_data
    save_user(validData)
else
    handle_errors(validator.get_errors)
end
```


You can use modifiers separately or can combine them with validation:

```ruby
validator = LIVR::Validator.new({
    'email' => [ 'required', 'trim', 'email', 'to_lc' ]
});
```


Feel free to register your own rules:

You can use aliases (prefferable, syntax covered by the specification) for a lot of cases:

```ruby
validator = LIVR::Validator.new({
    'password' => ['required', 'strong_password']
});

validator.register_aliased_rule({
    'name' => 'strong_password',
    'rules' => { 'min_length' => 6},
    'error' => 'WEAK_PASSWORD'
});
```

Or you can write more sophisticated rules directly:

```ruby
validator = LIVR::Validator.new({
    'password' => ['required', 'strong_password']
})

class StrongPassword
    def call(value, *other_args)
        # We already have "required" rule to check that the value is present
        return if value == nil || value == ""
        if value.length < 6
            return 'WEAK_PASSWORD'
        end
    end
end

validator.register_rules(strong_password: StrongPassword)

```

# LIVR 2.5 RULES

[LIVR 2.5](https://github.com/koorchik/LIVR/blob/master/drafts/v2.5.md) only adds rules to LIVR 2.0
(see [the changes](https://livr-spec.org/changes.html#v2-5)). The rules added in LIVR 2.5 are available by default:

 * types and numbers: `boolean`, `not_one_of`, `max_decimals`
 * strings: `digits`, `starts_with`, `ends_with`, `contains`
 * dates and times: `iso_date` with `min` and `max`, `iso_datetime`, `iso_time`
 * presence: `required_if`
 * metarules: `when`, `values`, `keys`, `any`
 * lists: `list_length`, `unique`
 * modifiers: `split`
 * formats: `uuid`, `ip`, `cidr`, `hostname`, `base64`, `hex`, `digest`, `mongo_id`, `hex_color`, `mac`, `e164`, `semver`, `jwt`
 * checksums: `luhn`, `credit_card`, `iban`

```ruby
validator = LIVR::Validator.new({
    'type'       => [ 'required', { 'one_of' => ['person', 'company'] } ],
    'vat_number' => { 'required_if' => { 'type' => 'company' } },
    'subscribe'  => 'boolean',
    'email'      => [ 'email', { 'when' => ['subscribe', ['boolean', { 'eq' => true }], 'required'] } ],
    'birth_date' => { 'iso_date' => { 'max' => 'today' } },
    'tags'       => [ { 'split' => ',' }, { 'list_length' => [1, 10] }, 'unique' ]
});
```

A rule that you register with the name of a standard rule replaces it.

Wrong arguments are schema errors: `LIVR::Validator.new({ 'flag' => { 'boolean' => 1 } }).prepare` raises an error
(`validate` prepares the validator too). `nil` as the argument is one `nil` argument, so `{ 'boolean' => nil }`
is a schema error too. The LIVR 2.0 rules and your own rules get no arguments for it, as in LIVR 2.0:
`{ 'iso_date' => nil }` is `'iso_date'`, and `{ 'my_rule' => nil }` calls `MyRule.new` without arguments.

`today`, `yesterday` and `tomorrow` are the current date in UTC, from the system clock. In tests, fix the clock with
`travel_to` from `ActiveSupport::Testing::TimeHelpers` or with Timecop:

```ruby
include ActiveSupport::Testing::TimeHelpers

travel_to(Time.utc(2026, 10, 18, 12)) do
    validator.validate(user_data)
end
```

LIVR 2.5 also fixes rules that refer to other fields (`equal_to_field` and your own rules): in an alias and in an
`or` rule they see the fields next to the field, in an item of `list_of` they see no fields. In LIVR 2.0 they saw
only the value itself. `iso_date` uses the proleptic Gregorian calendar, as ISO 8601: `1582-10-10` is a valid date
and `1500-02-29` is not (earlier versions used the Julian calendar before October 1582). `url` rejects a dot after
the host (`https://example.com.`), host labels longer than 63 characters and ports above 65535, and accepts one-digit
ports (`https://example.com:8`).

# DESCRIPTION
This ruby gem is an implementation of LIVR Specification.
See ['LIVR Specification'](http://livr-spec.org) for detailed documentation and list of supported rules.

Features:

 * Rules are declarative and language independent
 * Any number of rules for each field
 * Return together errors for all fields
 * Excludes all fields that do not have validation rules described
 * Has possibility to validatate complex hierarchical structures
 * Easy to describe and undersand rules
 * Returns understandable error codes(not error messages)
 * Easy to add own rules
 * Rules are be able to change results output ("trim", "nested\_object", for example)
 * Multipurpose (user input validation, configs validation, contracts programming etc)

# INSTALL

#### as a gem

```bash
gem install ruby-livr
```

#### in rails

Add to Gemfile

```ruby
gem "ruby-livr"
```


# AUTHORS

## Ruby implementation
Vitaliy Yanchuk (@fuksito)

## Idea and specification
Viktor Turskyi (@koorchik)
