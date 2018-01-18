require 'spec_helper.rb'

RSpec.describe "rules_replacement" do

  class PatchedRule < LIVR::Rule

    def initialize(rule_name, rule_builder)
      @rule_name = rule_name
      @rule_builder = rule_builder
    end

    def new(*args)
      @rule_args = args
      @rule_validator = @rule_builder.new(*args)
      self
    end

    def call(*args)
      error_code = @rule_validator.call(*args)
      if error_code
        return {
          "code" => error_code,
          "rule" => { @rule_name => @rule_args }
        }
      end
    end
  end

  it 'Validate data with registered rules' do
    # Patch rules
    default_rules = LIVR::DEFAULT_RULES

    original_rules = {}
    new_rules      = {}
    default_rules.each do |rule_name, rule_builder|
      original_rules[rule_name] = rule_builder
      new_rules[rule_name] = PatchedRule.new(rule_name, rule_builder)
    end

    LIVR::Validator.register_default_rules(new_rules)

    # Test
    validator = LIVR::Validator.new({
        "name" =>  ['required'],
        "phone" => { "max_length" => 10 }
    })

    output = validator.validate({
        "phone" => '123456789123456'
    })

    expect(output).to eq(false)
    expect(validator.get_errors).to eq({
            "name" => {
                "code" => 'REQUIRED',
                "rule" => { "required" => [] },
            },
            "phone" => {
                "code" => 'TOO_LONG',
                "rule" => { "max_length" => [10] },
            }
      })

     # Restore
    LIVR::Validator.register_default_rules(original_rules)
  end
end