require "test_helper"
require "json"

class JsonSchemerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JsonSchemer::VERSION
  end

  def test_it_does_something_useful
    schema = {
      'type' => 'object',
      'maxProperties' => 4,
      'minProperties' => 1,
      'required' => [
        'one'
      ],
      'properties' => {
        'one' => {
          'type' => 'string',
          'maxLength' => 5,
          'minLength' => 3,
          'pattern' => '\w+'
        },
        'two' => {
          'type' => 'integer',
          'minimum' => 10,
          'maximum' => 100,
          'multipleOf' => 5
        },
        'three' => {
          'type' => 'array',
          'maxItems' => 2,
          'minItems' => 2,
          'uniqueItems' => true,
          'contains' => {
            'type' => 'integer'
          }
        }
      },
      'additionalProperties' => {
        'type' => 'string'
      },
      'propertyNames' => {
        'type' => 'string',
        'pattern' => '\w+'
      },
      'dependencies' => {
        'one' => [
          'two'
        ],
        'two' => {
          'minProperties' => 1
        }
      }
    }
    data = {
      'one' => 'value',
      'two' => 100,
      'three' => [1, 2],
      '123' => 'x'
    }
    # assert JsonSchemer.valid?(schema, data)
    errors = JsonSchemer.validate(schema, data)
    p errors.to_a
    assert errors.none?
  end

  def test_json_schema_test_suite
    Dir['JSON-Schema-Test-Suite/tests/draft7/**/*.json'].each_with_object({}) do |file, out|
      JSON.parse(File.read(file)).each do |defn|
        schema = defn.fetch('schema')
        tests = defn.fetch('tests')
        defn.fetch('tests').each do |test|
          errors = begin
            JsonSchemer.validate(schema, test.fetch('data')).to_a
          rescue => e
            [e.message]
          end
          passed = errors.size == 0
          if passed != test.fetch('valid')
            out[file] ||= []
            out[file] << {
              :schema => schema,
              :test => test,
              :errors => errors
            }
          end
        end
      end
    end.each do |file, failures|
      puts "file: #{file}"
      puts
      failures.each do |failure|
        puts "schema: #{failure.fetch(:schema)}"
        puts "test: #{failure.fetch(:test)}"
        puts "errors: #{failure.fetch(:errors)}"
        puts
      end
      puts
    end
  end
end
