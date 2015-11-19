RSpec.describe Dry::Validation do
  let(:schema) do
    Class.new(Dry::Validation::Schema) do
      key(:email) { |email| email.filled? }

      key(:age) do |age|
        age.int? & age.gt?(18)
      end

      key(:address) do |address|
        address.key(:city) do |city|
          city.min_size?(3)
        end

        address.key(:street) do |street|
          street.filled?
        end

        address.key(:country) do |country|
          country.key(:name, &:filled?)
          country.key(:code, &:filled?)
        end
      end

      key(:phone_numbers) do |phone_numbers|
        phone_numbers.each(&:str?)
      end
    end
  end

  describe 'defining schema' do
    let(:validation) { schema.new }

    let(:attrs) do
      {
        email: 'jane@doe.org',
        age: 19,
        address: { city: 'NYC', street: 'Street 1/2', country: { code: 'US', name: 'USA' } },
        phone_numbers: [
          '123456', '234567'
        ]
      }.freeze
    end

    it 'passes when attributes are valid' do
      expect(validation.(attrs)).to be_empty
    end

    it 'validates presence of an email and min age value' do
      expect(validation.(attrs.merge(email: '', age: 18))).to match_array([
        [:error, [:input, [:age, 18, [:rule, [:age, [:predicate, [:gt?, [18]]]]]]]],
        [:error, [:input, [:email, "", [:rule, [:email, [:predicate, [:filled?, []]]]]]]]
      ])
    end

    it 'validates presence of the email key and type of age value' do
      expect(validation.(name: 'Jane', age: '18', address: attrs[:address], phone_numbers: attrs[:phone_numbers])).to match_array([
        [:error, [:input, [:age, "18", [:rule, [:age, [:predicate, [:int?, []]]]]]]],
        [:error, [:input, [:email, nil, [:rule, [:email, [:predicate, [:key?, [:email]]]]]]]]
      ])
    end

    it 'validates presence of the address and phone_number keys' do
      expect(validation.(email: 'jane@doe.org', age: 19)).to match_array([
        [:error, [:input, [:address, nil, [:rule, [:address, [:predicate, [:key?, [:address]]]]]]]],
        [:error, [:input, [:phone_numbers, nil, [:rule, [:phone_numbers, [:predicate, [:key?, [:phone_numbers]]]]]]]]
      ])
    end

    it 'validates presence of keys under address and min size of the city value' do
      expect(validation.(attrs.merge(address: { city: 'NY' }))).to match_array([
        [:error, [
          :input, [
            :address, {city: "NY"},
            [
              [:input, [:city, "NY", [:rule, [:city, [:predicate, [:min_size?, [3]]]]]]],
              [:input, [:street, nil, [:rule, [:street, [:predicate, [:key?, [:street]]]]]]],
              [:input, [:country, nil, [:rule, [:country, [:predicate, [:key?, [:country]]]]]]]
            ]
          ]
        ]]
      ])
    end

    it 'validates address code and name values' do
      expect(validation.(attrs.merge(address: attrs[:address].merge(country: { code: 'US', name: '' })))).to match_array([
        [:error, [
          :input, [
            :address, {city: "NYC", street: "Street 1/2", country: {code: "US", name: ""}},
            [
              [
                :input, [
                  :country, {code: "US", name: ""}, [
                    [
                      :input, [
                        :name, "", [:rule, [:name, [:predicate, [:filled?, []]]]]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]]
      ])
    end
  end
end