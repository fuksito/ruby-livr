require 'spec_helper.rb'

RSpec.describe "custom_filters" do
  class MyTrim < LIVR::Rule
    def call(value, user_data, field_results)
      return if is_no_value(value) || value.is_a?(Hash)
      field_results << value.to_s.strip
      return
    end
  end

  class MyLc < LIVR::Rule
    def call(value, user_data, field_results)
      return if is_no_value(value) || value.is_a?(Hash)
      field_results << value.to_s.downcase
      return
    end
  end

  class MyUcfirst < LIVR::Rule
    def call(value, user_data, field_results)
      return if is_no_value(value) || value.is_a?(Hash)
      field_results << value[0].capitalize + value[1..-1]
      return
    end
  end

  LIVR::Validator.register_default_rules(
      my_trim:    MyTrim,
      my_lc:      MyLc,
      my_ucfirst: MyUcfirst
    )

  it 'Validate data with registered rules' do
    validator = LIVR::Validator.new(
      "word1" => ['my_trim', 'my_lc', 'my_ucfirst'],
      "word2" => ['my_trim', 'my_lc'],
      "word3" => ['my_ucfirst'],
    )

    output = validator.validate(
      "word1" => ' wordOne ',
      "word2" => ' wordTwo ',
      "word3" => 'wordThree ',
      )

    expect(output).to eq( "word1" => 'Wordone',
                          "word2" => 'wordtwo',
                          "word3" => 'WordThree ',
                        )
  end

end

