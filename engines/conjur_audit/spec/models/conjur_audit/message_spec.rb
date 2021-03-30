# frozen_string_literal: true

require 'rails_helper'

module ConjurAudit
  RSpec.describe(Message, type: :model) do
    describe '.matching_sdata' do
      it 'filters on structured data' do
        foo = add_message("foo", sdata: { foo: { present: true } })
        bar = add_message("bar", sdata: { bar: { present: true } })

        msgs = Message.matching_sdata(foo: { present: true }).all
        expect(msgs).to include(eq(foo))
        expect(msgs).to_not include(eq(bar))
      end
    end
  end
end
