# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation) do
  let(:authenticator_name) { 'authn-dummy' }
  let(:service_name) { 'dummy_service' }
  let(:restriction_name) { 'user_email' }
  let(:general_annotation_name) { "#{authenticator_name}/#{restriction_name}" }
  let(:service_specific_annotation_name) { "#{authenticator_name}/#{service_name}/#{restriction_name}" }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "GetServiceSpecificRestrictionFromAnnotation" do
    context "Annotation is general" do
      subject do
        Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation.new.call(
          annotation_name: general_annotation_name,
          authenticator_name: authenticator_name,
          service_id: nil
        )
      end

      it "returns nil name and true" do
        returned_restriction_name, returned_is_general_restriction = subject
        expect(returned_restriction_name).to eql(nil)
        expect(returned_is_general_restriction).to eql(true)
      end
    end

    context "Annotation is with service id" do
      subject do
        Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation.new.call(
          annotation_name: service_specific_annotation_name,
          authenticator_name: authenticator_name,
          service_id: service_name
        )
      end

      it "returns restriction name and false" do
        returned_restriction_name, returned_is_general_restriction = subject
        expect(returned_restriction_name).to eql(restriction_name)
        expect(returned_is_general_restriction).to eql(false)
      end
    end

    context "Annotation is invalid" do
      context "Annotation built from one part" do
        subject do
          Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new.call(
            annotation_name: "aaa",
            authenticator_name: authenticator_name,
            service_id: service_name
          )
        end

        it "returns nil,nil" do
          returned_restriction_name, returned_is_general_restriction = subject
          expect(returned_restriction_name).to eql(nil)
          expect(returned_is_general_restriction).to eql(nil)
        end
      end

      context "Annotation with wrong authenticator name and no service id" do
        subject do
          Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new.call(
            annotation_name: "authn-wrong/bla",
            authenticator_name: authenticator_name,
            service_id: service_name
          )
        end

        it "returns nil,nil" do
          returned_restriction_name, returned_is_general_restriction = subject
          expect(returned_restriction_name).to eql(nil)
          expect(returned_is_general_restriction).to eql(nil)
        end
      end

      context "Annotation with wrong authenticator name with service id" do
        subject do
          Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new.call(
            annotation_name: "authn-wrong/bla/ya",
            authenticator_name: authenticator_name,
            service_id: service_name
          )
        end

        it "returns nil,nil" do
          returned_restriction_name, returned_is_general_restriction = subject
          expect(returned_restriction_name).to eql(nil)
          expect(returned_is_general_restriction).to eql(nil)
        end
      end

      context "Annotation with service id and then authenticator name" do
        subject do
          Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new.call(
            annotation_name: "#{service_name}/#{authenticator_name}",
            authenticator_name: authenticator_name,
            service_id: service_name
          )
        end

        it "returns nil,nil" do
          returned_restriction_name, returned_is_general_restriction = subject
          expect(returned_restriction_name).to eql(nil)
          expect(returned_is_general_restriction).to eql(nil)
        end
      end

      context "More than three part annotation" do
        subject do
          Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new.call(
            annotation_name: "#{authenticator_name}/#{service_name}/a/b",
            authenticator_name: authenticator_name,
            service_id: service_name
          )
        end

        it "returns nil,nil" do
          returned_restriction_name, returned_is_general_restriction = subject
          expect(returned_restriction_name).to eql(nil)
          expect(returned_is_general_restriction).to eql(nil)
        end
      end
    end
  end
end
