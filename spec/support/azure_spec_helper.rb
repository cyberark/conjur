
shared_context "azure setup" do

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:global_annotation_type) { "authn-azure" }

  def define_host_annotation(host_annotation_type, host_annotation_key, host_annotation_value)
    allow(host_annotation_type).to receive(:values)
                                     .and_return(host_annotation_type)
    allow(host_annotation_type).to receive(:[])
                                     .with(:name)
                                     .and_return(host_annotation_key)
    allow(host_annotation_type).to receive(:[])
                                     .with(:value)
                                     .and_return(host_annotation_value)
  end

  before(:each) do
    define_host_annotation(subscription_id_annotation, "#{global_annotation_type}/subscription-id", "some-subscription-id-value")
    define_host_annotation(resource_group_annotation,"#{global_annotation_type}/resource-group", "some-resource-group-value")
    define_host_annotation(user_assigned_identity_annotation,"#{global_annotation_type}/user-assigned-identity", "some-user-assigned-identity-value")
  end
end