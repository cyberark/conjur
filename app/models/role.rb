# frozen_string_literal: true

class Role < Sequel::Model
  extend Forwardable
  include HasId

  unrestrict_primary_key

  one_to_many(
    :memberships,
    class: :RoleMembership,
    extend: MembershipSearch,
    search_key: :member_id
  )
  one_to_many(
    :memberships_as_member,
    class: :RoleMembership,
    key: :member_id,
    extend: MembershipSearch,
    search_key: :role_id
  )
  one_to_one :credentials, reciprocal: :role

  alias id role_id

  def as_json options = {}
    options[:exclude] ||= []
    options[:exclude] << :credentials

    super(options).tap do |response|
      response["id"] = response.delete("role_id")
      write_id_to_json(response, "policy")
    end
  end

  class << self
    def that_can(permission, resource)
      Role.from(
        ::Sequel.function(:roles_that_can, permission.to_s, resource.pk)
      )
    end

    def make_full_id(id, account)
      tokens = id.split(":", 3) rescue []
      if tokens.size < 2
        raise ArgumentError, "Expected at least 2 tokens in #{id}"
      end

      account, kind, id = (tokens.size == 2 ? [account] + tokens : tokens)
      [account, kind, id].join(":")
    end

    def roleid_from_username(account, login)
      tokens = login.split('/', 2)
      tokens.unshift('user') if tokens.length == 1
      tokens.unshift(account)
      tokens.join(":")
    end

    def username_from_roleid(roleid)
      _, kind, id = roleid.split(":", 3)
      return id if kind == 'user'

      [kind, id].join('/')
    end
  end

  dataset_module do
    def member_of(role_ids)
      filter_memberships = Set.new(
        role_ids.map { |id| Role[id] }.compact.map(&:role_id)
      )
      where(role_id: filter_memberships.to_a)
    end

    def by_login login, account:
      self[role_id: Role.roleid_from_username(account, login)]
    end
  end

  def password=(password)
    modify_credentials do |credentials|
      credentials.password = password
    end
  end

  def valid_origin?(ip_addr)
    ip = IPAddr.new(ip_addr)
    restricted_to.blank? || restricted_to.any? do |cidr|
      cidr.include?(ip)
    end
  end

  def restricted_to
    self.credentials ||= Credentials.new(role: self)
    self.credentials.restricted_to
  end

  def restricted_to=(restricted_to)
    modify_credentials do |credentials|
      credentials.restricted_to = restricted_to
    end
  end

  def api_key
    unless self.credentials
      _, kind, id = self.id.split(":", 3)
      allowed_kind = %w[user host deputy].member?(kind)
      raise "Role #{id} has no credentials" unless allowed_kind

      self.credentials = Credentials.create(role: self)
    end

    self.credentials.api_key
  end

  def login
    self.class.username_from_roleid(role_id)
  end

  def resource?
    Resource[id].present?
  end

  def resource
    Resource[id] || raise("Resource not found for #{id}")
  end

  # All Roles of kind "layer" which this role is a direct member of.
  def layers
    memberships_as_member_dataset
      .where(Sequel.lit('kind(role_id) = \'layer\''))
      .map(&:role)
  end

  def direct_memberships_dataset(search_options = {})
    memberships_as_member_dataset.search(**search_options)
      .select(:role_memberships.*)
  end

  def members_dataset(search_options = {})
    memberships_dataset.search(**search_options)
      .select(:role_memberships.*)
  end

  # Role grants are performed by the policy loader, but not exposed through the
  # API.
  def grant_to(member, options = {})
    options[:admin_option] ||= false
    options[:member] = member

    add_membership(options)
  rescue Sequel::UniqueConstraintViolation
    # Membership grant already exists
  end

  def allowed_to?(privilege, resource)
    Role.from(
      Sequel.function(:is_role_allowed_to, id, privilege.to_s, resource.id)
    ).first[:is_role_allowed_to]
  end

  def all_roles
    Role.from(Sequel.function(:all_roles, id))
  end

  def ancestor_of?(role)
    Role.from(
      Sequel.function(:is_role_ancestor_of, id, role.id)
    ).first[:is_role_ancestor_of]
  end

  def graph
    Role.from(Sequel.function(:role_graph, id))
      .order(:parent, :child)
      .all
      .map(&:values)
  end

  private

  def modify_credentials
    credentials = self.credentials ||= Credentials.new(role: self)
    yield(credentials)
    credentials.save(raise_on_save_failure: true)
  end
end
