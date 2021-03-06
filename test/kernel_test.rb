require 'test_helper'
require 'bigdecimal'
require 'lotus/utils/kernel'

describe Lotus::Utils::Kernel do
  describe '.Array' do
    describe 'successful operations' do
      before do
        ResultSet = Struct.new(:records) do
          def to_a
            records.to_a.sort
          end
        end

        Response = Struct.new(:status, :headers, :body) do
          def to_ary
            [status, headers, body]
          end
        end

        @result = Lotus::Utils::Kernel.Array(input)
      end

      after do
        Object.send(:remove_const, :ResultSet)
        Object.send(:remove_const, :Response)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns an empty array' do
          @result.must_equal nil
        end
      end

      describe 'when true is given' do
        let(:input) { true }

        it 'returns an empty array' do
          @result.must_equal [true]
        end
      end

      describe 'when false is given' do
        let(:input) { false }

        it 'returns an empty array' do
          @result.must_equal [false]
        end
      end

      describe 'when an object is given' do
        let(:input) { Object.new }

        it 'returns an array' do
          @result.must_equal [input]
        end
      end

      describe 'when an array is given' do
        let(:input) { [Object.new] }

        it 'returns an array' do
          @result.must_equal input
        end
      end

      describe 'when a nested array is given' do
        let(:input) { [1, [2, 3]] }

        it 'returns a flatten array' do
          @result.must_equal [1,2,3]
        end
      end

      describe 'when an array with nil values is given' do
        let(:input) { [1, [nil, 3]] }

        it 'returns a compacted array' do
          @result.must_equal [1,3]
        end
      end

      describe 'when an array with duplicated values is given' do
        let(:input) { [2, [2, 3]] }

        it 'returns an array with uniq values' do
          @result.must_equal [2,3]
        end
      end

      describe 'when a set is given' do
        let(:input) { Set.new([33,12]) }

        it 'returns an array with uniq values' do
          @result.must_equal [33, 12]
        end
      end

      describe 'when a object that implements #to_a is given' do
        let(:input) { ResultSet.new([2,1,3]) }

        it 'returns an array' do
          @result.must_equal [1,2,3]
        end
      end

      describe 'when a object that implements #to_ary is given' do
        let(:input) { Response.new(200, {}, 'hello') }

        it 'returns an array' do
          @result.must_equal [200, {}, 'hello']
        end
      end
    end

    describe 'failure operations' do
      describe "when a object that doesn't implements #nil? is given" do
        let(:input) { BasicObject.new }

        it 'raises an error' do
          -> { Lotus::Utils::Kernel.Array(input) }.must_raise NoMethodError
        end
      end
    end
  end

  describe '.Set' do
    before do
      UuidSet = Class.new do
        def initialize(*uuids)
          @uuids = uuids
        end

        def to_set
          Set.new.tap do |set|
            @uuids.each {|uuid| set.add(uuid) }
          end
        end
      end

      BaseObject = Class.new(BasicObject) do
        def nil?
          false
        end
      end
    end

    after do
      Object.send(:remove_const, :UuidSet)
      Object.send(:remove_const, :BaseObject)
    end

    describe 'successful operations' do
      before do
        @result = Lotus::Utils::Kernel.Set(input)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns nil' do
          @result.must_equal nil
        end
      end

      describe 'when true is given' do
        let(:input) { true }

        it 'returns a set' do
          @result.must_equal Set.new([true])
        end
      end

      describe 'when false is given' do
        let(:input) { false }

        it 'returns a set' do
          @result.must_equal Set.new([false])
        end
      end

      describe 'when an object is given' do
        let(:input) { Object.new }

        it 'returns an set' do
          @result.must_equal Set.new([input])
        end
      end

      describe 'when an array is given' do
        let(:input) { [1] }

        it 'returns an set' do
          @result.must_equal Set.new(input)
        end
      end

      describe 'when an hash is given' do
        let(:input) { Hash[a: 1] }

        it 'returns an set' do
          @result.must_equal Set.new([[:a, 1]])
        end
      end

      describe 'when a set is given' do
        let(:input) { Set.new([Object.new]) }

        it 'returns self' do
          @result.must_equal input
        end
      end

      describe 'when a nested array is given' do
        let(:input) { [1, [2, 3]] }

        it 'returns it wraps in a set' do
          @result.must_equal Set.new([1, [2, 3]])
        end
      end

      describe 'when an array with nil values is given' do
        let(:input) { [1, [nil, 3]] }

        it 'returns it wraps in a set' do
          @result.must_equal Set.new([1, [nil, 3]])
        end
      end

      describe 'when an set with duplicated values is given' do
        let(:input) { [2, 3, 3] }

        it 'returns an set with uniq values' do
          @result.must_equal Set.new([2,3])
        end
      end

      describe 'when an set with nested duplicated values is given' do
        let(:input) { [2, [2, 3]] }

        it 'returns it wraps in a set' do
          @result.must_equal Set.new([2, [2,3]])
        end
      end

      describe 'when a object that implements #to_set is given' do
        let(:input) { UuidSet.new(*args) }
        let(:args)  { [SecureRandom.uuid, SecureRandom.uuid] }

        it 'returns an set' do
          @result.must_equal Set.new(args)
        end
      end
    end

    describe 'failure operations' do
      describe "when a an object that doesn't implement #nil?" do
        let(:input) { BasicObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Set(input) }.must_raise(NoMethodError)
        end
      end

      describe "when a an object that doesn't implement #respond_to?" do
        let(:input) { BaseObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Set(input) }.must_raise(NoMethodError)
        end
      end
    end
  end

  describe '.Hash' do
    before do
      Room = Class.new do
        def initialize(*args)
          @args = args
        end

        def to_h
          Hash[*@args]
        end
      end

      Record = Class.new do
        def initialize(attributes = {})
          @attributes = attributes
        end

        def to_hash
          @attributes
        end
      end

      BaseObject = Class.new(BasicObject) do
        def nil?
          false
        end
      end
    end

    after do
      Object.send(:remove_const, :Room)
      Object.send(:remove_const, :Record)
      Object.send(:remove_const, :BaseObject)
    end

    describe 'successful operations' do
      before do
        @result = Lotus::Utils::Kernel.Hash(input)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns an empty hash' do
          @result.must_equal nil
        end
      end

      describe 'when an hash is given' do
        let(:input) { Hash[l: 23] }

        it 'returns the input' do
          @result.must_equal input
        end
      end

      describe 'when an array is given' do
        let(:input) { [[:a, 1]] }

        it 'returns an hash' do
          @result.must_equal Hash[a: 1]
        end
      end

      describe 'when a set is given' do
        let(:input) { Set.new([['x', 12]]) }

        it 'returns an hash' do
          @result.must_equal Hash['x' => 12]
        end
      end

      describe 'when a object that implements #to_h is given' do
        let(:input) { Room.new(:key, 123456) }

        it 'returns an hash' do
          @result.must_equal Hash[key: 123456]
        end
      end

      describe 'when a object that implements #to_hash is given' do
        let(:input) { Record.new(name: 'L') }

        it 'returns an hash' do
          @result.must_equal Hash[name: 'L']
        end
      end
    end

    describe 'failure operations' do
      describe "when a an object that doesn't implement #nil?" do
        let(:input) { BasicObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(NoMethodError)
        end
      end

      describe "when a an object that doesn't implement #respond_to?" do
        let(:input) { BaseObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(NoMethodError)
        end
      end

      describe 'when true is given' do
        let(:input) { true }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
        end
      end

      describe 'when false is given' do
        let(:input) { false }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
        end
      end

      describe 'when an array with one element is given' do
        let(:input) { [1] }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
        end
      end

      if RUBY_VERSION >= '2.1'
        describe 'when an array with two elements is given' do
          let(:input) { [:a, 1] }

          it 'raises error' do
            -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
          end
        end
      end

      describe 'when a set of one element is given' do
        let(:input) { Set.new([1]) }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
        end
      end

      if RUBY_VERSION >= '2.1'
        describe 'when a set of two elements is given' do
          let(:input) { Set.new([:a, 1]) }

          it 'raises error' do
            -> { Lotus::Utils::Kernel.Hash(input) }.must_raise(TypeError)
          end
        end
      end
    end
  end

  describe '.Integer' do
    describe 'successful operations' do
      before do
        PersonFavNumber = Struct.new(:name) do
          def to_int
            23
          end
        end

        @result = Lotus::Utils::Kernel.Integer(input)
      end

      after do
        Object.send(:remove_const, :PersonFavNumber)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns nil' do
          @result.must_equal nil
        end
      end

      describe 'when a fixnum given' do
        let(:input) { 1 }

        it 'returns an integer' do
          @result.must_equal 1
        end
      end

      describe 'when a float is given' do
        let(:input) { 1.2 }

        it 'returns an integer' do
          @result.must_equal 1
        end
      end

      describe 'when a string given' do
        let(:input) { '23' }

        it 'returns an integer' do
          @result.must_equal 23
        end
      end

      describe 'when a string representing a float number is given' do
        let(:input) { '23.4' }

        it 'returns an integer' do
          @result.must_equal 23
        end
      end

      describe 'when an octal is given' do
        let(:input) { 011 }

        it 'returns the string representation' do
          @result.must_equal 9
        end
      end

      describe 'when a hex is given' do
        let(:input) { 0xf5 }

        it 'returns the string representation' do
          @result.must_equal 245
        end
      end

      describe 'when a bignum is given' do
        let(:input) { 13289301283 ** 2 }

        it 'returns an bignum' do
          @result.must_equal 176605528590345446089
        end
      end

      describe 'when a bigdecimal is given' do
        let(:input) { BigDecimal.new('12.0001') }

        it 'returns an bignum' do
          @result.must_equal 12
        end
      end

      describe 'when a complex number is given' do
        let(:input) { Complex(0.3) }

        it 'returns an integer' do
          @result.must_equal 0
        end
      end

      describe 'when a string representing a complex number is given' do
        let(:input) { '2.5/1' }

        it 'returns an integer' do
          @result.must_equal 2
        end
      end

      describe 'when a rational number is given' do
        let(:input) { Rational(0.3) }

        it 'returns an integer' do
          @result.must_equal 0
        end
      end

      describe 'when a string representing a rational number is given' do
        let(:input) { '2/3' }

        it 'returns an integer' do
          @result.must_equal 2
        end
      end

      describe 'when a time is given' do
        let(:input) { Time.at(0).utc }

        it 'returns the string representation' do
          @result.must_equal 0
        end
      end

      describe 'when an object that implements #to_int is given' do
        let(:input) { PersonFavNumber.new('Luca') }

        it 'returns an integer' do
          @result.must_equal 23
        end
      end
    end

    describe 'failure operations' do
      describe 'true is given' do
        let(:input) { true }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(TypeError)
        end
      end

      describe 'false is given' do
        let(:input) { false }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(TypeError)
        end
      end

      describe 'when a date is given' do
        let(:input) { Date.today }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(TypeError)
        end
      end

      describe 'when a datetime is given' do
        let(:input) { DateTime.now }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(TypeError)
        end
      end

      describe "when a an object that doesn't implement #nil? " do
        let(:input) { BasicObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(NoMethodError)
        end
      end

      describe "when a an object that doesn't implement any integer interface" do
        let(:input) { OpenStruct.new(color: 'purple') }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(TypeError)
        end
      end

      describe 'when a bigdecimal infinity is given' do
        let(:input) { BigDecimal.new('Infinity') }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(FloatDomainError)
        end
      end

      describe 'when a bigdecimal NaN is given' do
        let(:input) { BigDecimal.new('NaN') }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(FloatDomainError)
        end
      end

      describe 'when a big complex number is given' do
        let(:input) { Complex(2,3) }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(RangeError)
        end
      end

      describe 'when a big rational number is given' do
        let(:input) { Rational(-8) ** Rational(1, 3) }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Integer(input) }.must_raise(RangeError)
        end
      end
    end
  end

  describe '.String' do
    before do
      Book = Struct.new(:title)

      BaseObject = Class.new(BasicObject) do
        def nil?
          false
        end
      end

      SimpleObject = Class.new(BaseObject) do
        def to_s
          'simple object'
        end
      end

      Isbn = Struct.new(:code) do
        def to_str
          code.to_s
        end
      end
    end

    after do
      Object.send(:remove_const, :Book)
      Object.send(:remove_const, :BaseObject)
      Object.send(:remove_const, :SimpleObject)
      Object.send(:remove_const, :Isbn)
    end

    describe 'successful operations' do
      before do
        @result = Lotus::Utils::Kernel.String(input)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns nil' do
          @result.must_be_nil
        end
      end

      describe 'when true is given' do
        let(:input) { true }

        it 'returns nil' do
          @result.must_equal 'true'
        end
      end

      describe 'when false is given' do
        let(:input) { false }

        it 'returns nil' do
          @result.must_equal 'false'
        end
      end

      describe 'when an empty string is given' do
        let(:input) { '' }

        it 'returns it' do
          @result.must_equal ''
        end
      end

      describe 'when a string is given' do
        let(:input) { 'ciao' }

        it 'returns it' do
          @result.must_equal 'ciao'
        end
      end

      describe 'when an integer is given' do
        let(:input) { 23 }

        it 'returns the string representation' do
          @result.must_equal '23'
        end
      end

      describe 'when a float is given' do
        let(:input) { 3.14 }

        it 'returns the string representation' do
          @result.must_equal '3.14'
        end
      end

      describe 'when an octal is given' do
        let(:input) { 013 }

        it 'returns the string representation' do
          @result.must_equal '11'
        end
      end

      describe 'when a hex is given' do
        let(:input) { 0xc0ff33 }

        it 'returns the string representation' do
          @result.must_equal '12648243'
        end
      end

      describe 'when a big decimal is given' do
        let(:input) { BigDecimal.new(7944.2343, 10) }

        it 'returns the string representation' do
          @result.must_equal '0.79442343E4'
        end
      end

      describe 'when a big decimal infinity is given' do
        let(:input) { BigDecimal.new('Infinity') }

        it 'returns the string representation' do
          @result.must_equal 'Infinity'
        end
      end

      describe 'when a big decimal NaN is given' do
        let(:input) { BigDecimal.new('NaN') }

        it 'returns the string representation' do
          @result.must_equal 'NaN'
        end
      end

      describe 'when a complex is given' do
        let(:input) { Complex(11,2) }

        it 'returns the string representation' do
          @result.must_equal '11+2i'
        end
      end

      describe 'when a rational is given' do
        let(:input) { Rational(-22) }

        it 'returns the string representation' do
          @result.must_equal '-22/1'
        end
      end

      describe 'when an empty array is given' do
        let(:input) { [] }

        it 'returns the string representation' do
          @result.must_equal '[]'
        end
      end

      describe 'when an array of integers is given' do
        let(:input) { [1,2,3] }

        it 'returns the string representation' do
          @result.must_equal '[1, 2, 3]'
        end
      end

      describe 'when an array of strings is given' do
        let(:input) { %w[a b c] }

        it 'returns the string representation' do
          @result.must_equal '["a", "b", "c"]'
        end
      end

      describe 'when an array of objects is given' do
        let(:input) { [Object.new] }

        it 'returns the string representation' do
          @result.must_match '[#<Object:'
        end
      end

      describe 'when an empty hash is given' do
        let(:input) { {} }

        it 'returns the string representation' do
          @result.must_equal '{}'
        end
      end

      describe 'when an hash is given' do
        let(:input) { {a: 1, 'b' => 2} }

        it 'returns the string representation' do
          @result.must_equal '{:a=>1, "b"=>2}'
        end
      end

      describe 'when a symbol is given' do
        let(:input) { :lotus }

        it 'returns the string representation' do
          @result.must_equal 'lotus'
        end
      end

      describe 'when an struct is given' do
        let(:input) { Book.new('DDD') }

        it 'returns the string representation' do
          @result.must_equal '#<struct Book title="DDD">'
        end
      end

      describe 'when an open struct is given' do
        let(:input) { OpenStruct.new(title: 'DDD') }

        it 'returns the string representation' do
          @result.must_equal '#<OpenStruct title="DDD">'
        end
      end

      describe 'when a date is given' do
        let(:input) { Date.parse('2014-04-11') }

        it 'returns the string representation' do
          @result.must_equal '2014-04-11'
        end
      end

      describe 'when a datetime is given' do
        let(:input) { DateTime.parse('2014-04-11 09:45') }

        it 'returns the string representation' do
          @result.must_equal '2014-04-11T09:45:00+00:00'
        end
      end

      describe 'when a time is given' do
        let(:input) { Time.at(0).utc }

        it 'returns the string representation' do
          @result.must_equal '1970-01-01 00:00:00 UTC'
        end
      end

      describe 'when a class is given' do
        let(:input) { Fixnum }

        it 'returns the string representation' do
          @result.must_equal 'Fixnum'
        end
      end

      describe 'when a module is given' do
        let(:input) { Lotus }

        it 'returns the string representation' do
          @result.must_equal 'Lotus'
        end
      end

      describe 'when an object implements #to_s' do
        let(:input) { SimpleObject.new }

        it 'returns the string representation' do
          @result.must_equal 'simple object'
        end
      end

      describe 'when an object implements #to_str' do
        let(:input) { Isbn.new(123) }

        it 'returns the string representation' do
          @result.must_equal '123'
        end
      end
    end

    describe 'failure operations' do
      describe "when a an object that doesn't implement #nil?" do
        let(:input) { BasicObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.String(input) }.must_raise(NoMethodError)
        end
      end

      describe "when a an object that doesn't implement a string interface" do
        let(:input) { BaseObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.String(input) }.must_raise(TypeError)
        end
      end
    end
  end

  describe '.Boolean' do
    before do
      Answer = Struct.new(:answer) do
        def to_bool
          case answer
          when 'yes' then true
          else false
          end
        end
      end
    end

    after do
      Object.send(:remove_const, :Answer)
    end

    describe 'successful operations' do
      before do
        @result = Lotus::Utils::Kernel.Boolean(input)
      end

      describe 'when nil is given' do
        let(:input) { nil }

        it 'returns nil' do
          @result.must_be_nil
        end
      end

      describe 'when true is given' do
        let(:input) { true }

        it 'returns true' do
          @result.must_equal true
        end
      end

      describe 'when false is given' do
        let(:input) { false }

        it 'returns false' do
          @result.must_equal false
        end
      end

      describe 'when 0 is given' do
        let(:input) { 0 }

        it 'returns false' do
          @result.must_equal false
        end
      end

      describe 'when 1 is given' do
        let(:input) { 1 }

        it 'returns true' do
          @result.must_equal true
        end
      end

      describe 'when 2 is given' do
        let(:input) { 2 }

        it 'returns false' do
          @result.must_equal false
        end
      end

      describe 'when -1 is given' do
        let(:input) { -1 }

        it 'returns false' do
          @result.must_equal false
        end
      end

      describe 'when "0" is given' do
        let(:input) { "0" }

        it 'returns false' do
          @result.must_equal false
        end
      end

      describe 'when "1" is given' do
        let(:input) { "1" }

        it 'returns true' do
          @result.must_equal true
        end
      end

      describe 'when an object is given' do
        let(:input) { Object.new }

        it 'returns true' do
          @result.must_equal true
        end
      end

      describe 'when the given object responds to #to_bool' do
        let(:input) { Answer.new('no') }

        it 'returns the result of the serialization' do
          @result.must_equal false
        end
      end
    end

    describe 'failure operations' do
      describe "when a an object that doesn't implement #respond_to?" do
        let(:input) { BasicObject.new }

        it 'raises error' do
          -> { Lotus::Utils::Kernel.Boolean(input) }.must_raise(NoMethodError)
        end
      end
    end
  end
end
