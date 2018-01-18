require 'spec_helper.rb'

def read_file(dir, filename)
  data = File.read dir.join("#{filename}.json")
  JSON.parse(data)
end

RSpec.describe "test_suite " do

  %w[ positive negative ].each do |spec_dir|
    context spec_dir do
      dirs = Pathname.new("#{SPEC_ROOT}/test_suite/#{spec_dir}").children.select(&:directory?)
      dirs.each do |dir|
        it dir.basename do
          rules = read_file(dir, "rules")
          input = read_file(dir, "input")

          validator = LIVR::Validator.new(rules)
          result = validator.validate(input)
          errors = validator.get_errors

          if spec_dir == 'positive'
            expected_result = read_file(dir, "output")
            expect(result).to eq(expected_result)
          else
            expected_errors = read_file(dir, "errors")
            expect(errors).to eq(expected_errors)
          end
        end
      end
    end
  end

end