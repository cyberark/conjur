shared_context "azure setup" do

  let(:test_service_id) { "MockService" }

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:system_assigned_identity_annotation) { double("SystemAssignedIdentityAnnotation") }

  let(:subscription_id_service_id_scoped_annotation) { double("SubscriptionIdServiceIdAnnotation") }
  let(:resource_group_service_id_scoped_annotation) { double("ResourceGroupAnnotation") }

  let(:global_annotation_type) { "authn-azure" }
  let(:granular_annotation_type) { "authn-azure/#{test_service_id}" }

  let(:non_azure_annotation) { double("NonAzureAnnotation") }

  def define_host_annotation(host_annotation_type:, host_annotation_key:, host_annotation_value:)
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
    define_host_annotation(
      host_annotation_type:  subscription_id_annotation,
      host_annotation_key:   "#{global_annotation_type}/subscription-id",
      host_annotation_value: "some-subscription-id-value"
    )
    define_host_annotation(
      host_annotation_type:  resource_group_annotation,
      host_annotation_key:   "#{global_annotation_type}/resource-group",
      host_annotation_value: "some-resource-group-value"
    )
    define_host_annotation(
      host_annotation_type:  user_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/user-assigned-identity",
      host_annotation_value: "some-user-assigned-identity-value"
    )
    define_host_annotation(
      host_annotation_type:  system_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/system-assigned-identity",
      host_annotation_value: "some-system-assigned-identity-value"
    )

    define_host_annotation(
      host_annotation_type:  subscription_id_service_id_scoped_annotation,
      host_annotation_key:   "#{granular_annotation_type}/subscription-id",
      host_annotation_value: "some-subscription-id-service-id-scoped-value"
    )
    define_host_annotation(
      host_annotation_type:  resource_group_service_id_scoped_annotation,
      host_annotation_key:   "#{granular_annotation_type}/resource-group",
      host_annotation_value: "some-resource-group-service-id-scoped-value"
    )
  end
end
