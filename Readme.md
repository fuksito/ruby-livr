[![Build Status](https://travis-ci.org/fuksito/ruby-livr.svg?branch=master)](https://travis-ci.org/fuksito/ruby-livr)

# LIVR Validator
LIVR.Validator - Lightweight validator supporting Language Independent Validation Rules Specification (LIVR)
Implements latest ['2.0 specification'](http://livr-spec.org)

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
