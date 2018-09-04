# frozen_string_literal: true

# MembershipSearch provides the `search`` extension method
# for Role membership datasets to allow text searching
# and paging of Role members
class MembershipSearch < Module

  def initialize(id_column)
    super() do 
      define_search
      define_filter_kind(id_column)
      define_textsearch(id_column)
      define_result_set(id_column)
    end
  end

  def define_search
    # @param search [String] - a search term in the resource id
    define_method :search do |search: nil, kind: nil|
      filter_kind(kind).textsearch(search)
    end
  end

  def define_filter_kind(id_column)
    define_method :filter_kind do |kind|
      return self unless kind

      kind_function = Sequel.function(:kind, id_column)
      where(kind_function => Array(kind))
    end
  end

  def define_textsearch(id_column)
    define_method :textsearch do |input|
      return self unless input
  
      # If I use 3 literal spaces, it gets send to PG as one space.
      query = Sequel.function(:plainto_tsquery, "english",
        Sequel.function(:translate, input.to_s, "./-", "   "))
  
      # Default weights for ts_rank_cd are {0.1, 0.2, 0.4, 1.0} for DCBA resp.
      # Sounds just about right. A are name and id, B is rest of annotations, C is kind.
      rank = Sequel.function(:ts_rank_cd, :textsearch, query)
  
      left_join(:resources_textsearch, resource_id: id_column)
        .where(Sequel.lit("? @@ textsearch", query))
        .order(Sequel.desc(rank))
    end
  end

  def define_result_set(id_column)
    # result_set renders a dataset to a result set using the
    # provided order and paging parameters
    define_method :result_set do |order_by: nil, offset: nil, limit: nil|
      scope = self

      order_by ||= id_column
      scope = scope.order(order_by)

      if offset || limit
        scope = scope.limit(
          (limit || 10).to_i,
          (offset || 0).to_i
        )
      end

      scope.all
    end
  end
end
