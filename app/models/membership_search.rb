# MembershipSearch provides the `search`` extension method
# for Roles.membership_dataset to allow text searching
# and paging of Role members
module MembershipSearch
  # @param search [String] - a search term in the resource id
  def search(search: nil, kind: nil)
    filter_kind(kind).textsearch(search)
  end

  def filter_kind(kind)
    return self unless kind

    where(Sequel.lit("kind(member_id) in ?", Array(kind))) 
  end

  def textsearch(input)
    return self unless input

    # If I use 3 literal spaces, it gets send to PG as one space.
    query = Sequel.function(:plainto_tsquery, "english",
                            Sequel.function(:translate, input.to_s, "./-", "   "))

    # Default weights for ts_rank_cd are {0.1, 0.2, 0.4, 1.0} for DCBA resp.
    # Sounds just about right. A are name and id, B is rest of annotations, C is kind.
    rank = Sequel.function(:ts_rank_cd, :textsearch, query)

    left_join(:resources_textsearch, resource_id: :member_id)
      .where(Sequel.lit("? @@ textsearch", query))
      .order(Sequel.desc(rank))
  end

  # result_set renders a dataset to a result set using the
  # provided order and paging parameters
  def result_set(order_by: nil, offset: nil, limit: nil)
    scope = self

    order_by ||= :member_id
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
