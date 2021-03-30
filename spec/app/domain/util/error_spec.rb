# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Util::ErrorClass') do
  context 'object' do
    let(:error_template) { 'An error occured' }

    subject(:error_class) { Util::ErrorClass.new(error_template) }

    it 'is of type RuntimeError' do
      expect { raise error_class }.to raise_error(RuntimeError)
    end

    it 'has the expected templated error' do
      expect { raise error_class }.to raise_error(error_template)
    end
  end

  context 'templating' do
    let(:error_template) { 'Variable is {0}.' }

    subject(:error_class) { Util::ErrorClass.new(error_template) }

    it 'works for nil' do
      expect { raise error_class, nil }.to raise_error('Variable is nil.')
    end

    it 'works for strings' do
      expect { raise error_class, '' }.to raise_error('Variable is .')
      expect { raise error_class, 'ABC' }.to raise_error('Variable is ABC.')
    end

    it 'works for Fixnums' do
      expect { raise error_class, 9 }.to raise_error('Variable is 9.')
      expect { raise error_class, 0 }.to raise_error('Variable is 0.')
    end

    it 'works for booleans' do
      expect { raise error_class, false }.to raise_error('Variable is false.')
      expect { raise error_class, true }.to raise_error('Variable is true.')
    end

    it 'works for objects' do
      expect { raise error_class, Class }.to raise_error('Variable is Class.')
      expect { raise error_class, Util::ErrorClass }.to raise_error('Variable is Util::ErrorClass.')
    end

    it 'works for arrays' do
      expect { raise error_class, %w[aA bB] }.to raise_error('Variable is ["aA", "bB"].')
    end

    it 'handles overflow args' do
      expect { raise error_class.new('AA', 'BB') }.to raise_error('Variable is AA.')
    end

    it 'handles underflow args' do
      expect { raise error_class }.to raise_error('Variable is {0}.')
    end

    context 'with multiple args' do
      let(:non_repeating_error_template) { 'Variables are {0} {1} {2} {3} {4} {5}.' }
      let(:mixed_error_template) { 'Variables are {2} {1} {2} {0} {4} {4}.' }

      subject(:non_repeating_error_class) { Util::ErrorClass.new(non_repeating_error_template) }
      subject(:mixed_error_class) { Util::ErrorClass.new(mixed_error_template) }

      it 'handles multiple args' do
        expect { raise non_repeating_error_class.new('00', '11', '22', '33', '44', '55') }
          .to raise_error('Variables are 00 11 22 33 44 55.')
      end

      it 'handles repeating and mixed args' do
        expect { raise mixed_error_class.new('00', '11', '22', '33', '44', '55') }
          .to raise_error('Variables are 22 11 22 00 44 44.')
      end
    end

    context 'with arg description' do
      let(:descriptive_error_template) { 'Variable is {0-var-description}.' }

      subject(:descriptive_error_class) { Util::ErrorClass.new(descriptive_error_template) }

      it 'ignores the description' do
        expect { raise descriptive_error_class, 'var' }
          .to raise_error('Variable is var.')
      end
    end
  end
end
