module Authentication
  module AuthnJwt
    class ExtractNestedValue
      def call(hash_map:, path:, path_separator: '/')
        path_parts = path.split(path_separator)
        hash_map.dig(*path_parts)
      end
    end
  end
end
