module DB
  module Preview
    class Slosilo_exists
      def is_exist?
        !Slosilo["authn:conjur"].nil?
      end
    end
  end
end