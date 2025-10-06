# frozen_string_literal: true

module CallSql
  module Sequel
    module Model
      def call_sql *a
        db.select(::Sequel.function(*a)).first.values
      end

      def select_from_function *a
        from(::Sequel.function(*a))
      end
    end
  end
  
  def self.insert
    ::Sequel::Model.extend(Sequel::Model)
  end
end
