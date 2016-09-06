# Stores a specific policy text and metadata which has been applied to the database.
# 
# A PolicyVersion is constructed on an existing 'policy' resource. PolicyVersion records are automatically
# assigned an incrementing +version+ number, just like Secrets.
#
# In addition to the 'policy' resource and the version, each record stores the following metadata:
#
# * +role+ the authenticated role who performed the policy load.
# * +owner+ the role which is designated as the owner of the policy records.
# * +created_at+ a timestamp.
# * +policy_text+ the text of the policy itself.
# * +policy_sha256+ the SHA-256 of the policy in hex digest form.
#
# The policy text is parsed when the PolicyVersion is validated. Parse errors are placed onto the 
# +#errors+ field, along with any other validation errors. The parsed policy is available through the
# +#recorsd+ field.
class PolicyVersion < Sequel::Model(:policy_versions)
  include HasId

  many_to_one :resource
  # The authenticated user who performs the policy load.
  many_to_one :role
  # The specified owner of the new records.
  many_to_one :owner, class: :Role

  attr_accessor :parse_error

  alias id resource_id
  alias current_user role
  alias policy resource
  alias policy= resource=

  def as_json options = {}
    super(options).tap do |response|
      response["id"] = response.delete("resource_id")
      %w(role owner).each do |field|
        write_id_to_json response, field
      end
    end
  end

  def validate
    super

    validates_presence [ :current_user, :owner, :policy_text ]

    if current_user && owner
      errors.add(:owner, "is not allowed as the owner role") unless current_user.all_roles([ owner.role_id ]).any?
    end

    try_load_records 

    if parse_error
      errors.add(:policy_text, parse_error.to_s)
    end
  end

  def before_save
    require 'digest'
    self.policy_sha256 = Digest::SHA256.hexdigest(policy_text)
  end


  def before_update
    raise Sequel::ValidationFailed, "Policy version cannot be updated once created"
  end

  def records
    try_load_records
    raise @parse_error if @parse_error
    @records
  end

  def try_load_records
    return if @records || @parse_error
    return unless policy_text && owner

    begin
      records = Conjur::Policy::YAML::Loader.load(policy_text)
      @records = Conjur::Policy::Resolver.resolve records, account, owner.role_id
    rescue
      @parse_error = $!
    end
  end
end
