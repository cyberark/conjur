# MembershipSearch provides the `search`` extension method
# for Roles.membership_dataset to allow text searching
# and paging of Role members
module MembershipSearch
  # @param search [String] - a search term in the resource id
  def search(search: nil, kind: nil)
    scope = self

    scope = scope.where(Sequel.lit("kind(member_id) in ?", Array(kind))) if kind

    # Filter by string search
    scope = scope.textsearch(search) if search

    scope
  end

  def textsearch(input)
    # If I use 3 literal spaces, it gets send to PG as one space.
    query = Sequel.function(:plainto_tsquery, "english",
                            Sequel.function(:translate, input.to_s, "./-", "   "))

    # Default weights for ts_rank_cd are {0.1, 0.2, 0.4, 1.0} for DCBA resp.
    # Sounds just about right. A are name and id, B is rest of annotations, C is kind.
    rank = Sequel.function(:ts_rank_cd, :textsearch, query)

    left_join(:resources_textsearch, resource_id: :member_id)
      .where("? @@ textsearch", query)
      .order(Sequel.desc(rank))
  end
end
