# frozen_string_literal: true

# Stores a policy which has been applied to the database, along with metadata such as the role
# which submitted the policy.
#
# A PolicyVersion is constructed on an existing 'policy' resource. PolicyVersion records are automatically
# assigned an incrementing +version+ number, just like Secrets.
#
# In addition to the 'policy' resource and the version, each PolicyVersion stores the following metadata:
#
# * +role+ the authenticated role who performed the policy load.
# * +created_at+ a timestamp.
# * +client_ip+ the IP address of the client that loaded the policy.
# * +policy_text+ the text of the policy itself.
# * +version+ the policy version
# * +policy_sha256+ the SHA-256 of the policy in hex digest form.
#
# The policy text is parsed when the PolicyVersion is validated. Parse errors are placed onto the
# +#errors+ field, along with any other validation errors. The parsed policy is available through the
# +#records+ field.
#
# Except when loading the root policy, the policy statements that are submitted by the authenticated role
# are enclosed within a +!policy+ statement, so that all the statements in the policy are scoped by the enclosing id.
# For example, suppose a PolicyVersion is being loaded for the policy +prod/myapp+. If policy being loaded
# contains a statement like +!layer+, then the layer id as loaded will be +prod/myapp+.

class PolicyVersion < Sequel::Model(:policy_versions)
  include HasId

  many_to_one :resource
  # The authenticated user who performs the policy load.
  many_to_one :role

  one_to_many :policy_log, key: %i[policy_id version]

  attr_accessor :policy_filename, :delete_permitted

  alias id resource_id
  alias current_user role
  alias policy resource
  alias policy= resource=

  dataset_module do
    def current
      from(Sequel.function(:current_policy_version)).first
    end
  end

  def initialize(*args, policy_parse: nil, **kwargs)
    super(*args, **kwargs)

    # policy_parse is not part of the data model, but allows us to operate
    # on an existing policy parse rather than parse it again.
    @policy_parse = policy_parse
  end

  def as_json options = {}
    super(options).tap do |response|
      response["id"] = response.delete("resource_id")
      %w[role].each do |field|
        write_id_to_json(response, field)
      end
    end
  end

  # Indicates whether explicit deletion is permitted.
  def delete_permitted?
    !!@delete_permitted
  end

  def validate
    super

    validates_presence([ :policy, :current_user, :policy_text ])

    return if errors.any?

    # If a parse error has occurred, don't attempt other validations.
    if policy_parse.error
      errors.add(:policy_text, policy_parse.reportable_error)
    else
      unless policy_parse.delete_records.empty? || delete_permitted?
        errors.add(:policy_text, "may not contain deletion statements")
      end
    end
  end

  def policy_parse
    @policy_parse ||= parse_policy
  end

  def parse_policy
    return unless policy_text

    root_policy = policy.kind == "policy" && policy.identifier == "root"

    Commands::Policy::Parse.new.call(
      account: account,
      policy_id: policy.identifier,
      owner_id: policy_admin.id,
      policy_text: policy_text,
      policy_filename: policy_filename,
      root_policy: root_policy
    )
  end

  def before_save
    require 'digest'
    self.policy_sha256 = Digest::SHA256.hexdigest(policy_text)
  end

  def after_save
    log_versions_to_expire
    remove_expired_versions
  rescue => e
    Rails.logger.error("Error while enforcing version retention limit for policy: '#{id}, #{e.inspect}'")
  end

  def log_versions_to_expire
    expired_versions.all.each do |policy_version|
      Rails.logger.debug(
        "Deleting policy version: #{policy_version.slice(
          :version,
          :resource_id,
          :role_id,
          :created_at,
          :client_ip
        )}]"
      )
    end
  end

  def expired_versions
    Sequel::Model.db[<<-SQL, resource_id, policies_version_limit, resource_id]
      WITH
      "ordered_versions" AS (
        SELECT * FROM "policy_versions" WHERE ("resource_id" = ?) ORDER BY "version" DESC LIMIT ?
      )
      SELECT * FROM "policy_versions" LEFT JOIN "ordered_versions"
      USING (
        "resource_id",
        "version",
        "role_id",
        "created_at",
        "client_ip"
      )
      WHERE (("ordered_versions"."resource_id" IS NULL) AND ("resource_id" = ?))
    SQL
  end

  def remove_expired_versions
    Sequel::Model.db[<<-SQL, resource_id, policies_version_limit, resource_id].delete
      WITH
        "ordered_versions" AS (
          SELECT * FROM "policy_versions" WHERE ("resource_id" = ?) ORDER BY "version" DESC LIMIT ?
        ),
        "delete_versions" AS (
          SELECT * FROM "policy_versions" LEFT JOIN "ordered_versions" USING ("resource_id", "version")
          WHERE (("ordered_versions"."resource_id" IS NULL) AND ("resource_id" = ?))
        )
      DELETE FROM "policy_versions"
      USING "delete_versions"
      WHERE "policy_versions"."resource_id" = "delete_versions"."resource_id" AND
            "policy_versions"."version" = "delete_versions"."version"
    SQL
  end

  def before_update
    raise Sequel::ValidationFailed, "Policy version cannot be updated once created"
  end

  def policy_admin
    policy.owner
  end

  def version
    self[:version]
  end

end
