# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Util::LogMessageClass') do
  context 'pre-determined, static log message' do
    let(:log_message) { 'some log message' }
    subject(:log_message_class) { Util::LogMessageClass.new(log_message) }

    it 'has the expected message' do
      expect(log_message_class.new.to_s).to eq(log_message)
    end
  end

  context 'templating' do
    let(:log_message_template) { 'Variable is {0}.' }

    subject(:log_message_class) { Util::LogMessageClass.new(log_message_template) }

    it 'works for nil' do
      expect(log_message_class.new(nil).to_s).to eq('Variable is nil.')
    end

    it 'works for strings' do
      expect(log_message_class.new('').to_s).to eq('Variable is .')
      expect(log_message_class.new('ABC').to_s).to eq('Variable is ABC.')
    end

    it 'works for Fixnums' do
      expect(log_message_class.new(9).to_s).to eq('Variable is 9.')
      expect(log_message_class.new(0).to_s).to eq('Variable is 0.')
    end

    it 'works for booleans' do
      expect(log_message_class.new(false).to_s).to eq('Variable is false.')
      expect(log_message_class.new(true).to_s).to eq('Variable is true.')
    end

    it 'works for objects' do
      expect(log_message_class.new(Class).to_s).to eq('Variable is Class.')
      expect(log_message_class.new(Util::LogMessageClass).to_s).to eq('Variable is Util::LogMessageClass.')
    end

    it 'works for arrays' do
      expect(log_message_class.new(%w[aA bB]).to_s).to eq('Variable is ["aA", "bB"].')
    end

    it 'handles overflow args' do
      expect(log_message_class.new('AA', 'BB').to_s).to eq('Variable is AA.')
    end

    it 'handles underflow args' do
      expect(log_message_class.new.to_s).to eq('Variable is {0}.')
    end

    context 'with multiple args' do
      let(:non_repeating_log_message_template) { 'Variables are {0} {1} {2} {3} {4} {5}.' }
      let(:mixed_log_message_template) { 'Variables are {2} {1} {2} {0} {4} {4}.' }

      subject(:non_repeating_log_message_class) { Util::LogMessageClass.new(non_repeating_log_message_template) }
      subject(:mixed_log_message_class) { Util::LogMessageClass.new(mixed_log_message_template) }

      it 'handles multiple args' do
        expect(non_repeating_log_message_class.new('00', '11', '22', '33', '44', '55').to_s)
          .to eq('Variables are 00 11 22 33 44 55.')
      end

      it 'handles repeating and mixed args' do
        expect(mixed_log_message_class.new('00', '11', '22', '33', '44', '55').to_s)
          .to eq('Variables are 22 11 22 00 44 44.')
      end
    end

    context 'with arg description' do
      let(:descriptive_log_message_template) { 'Variable is {0-var-description}.' }

      subject(:descriptive_log_message_class) { Util::LogMessageClass.new(descriptive_log_message_template) }

      it 'ignores the description' do
        expect(descriptive_log_message_class.new('var').to_s)
          .to eq('Variable is var.')
      end
    end
  end
end
