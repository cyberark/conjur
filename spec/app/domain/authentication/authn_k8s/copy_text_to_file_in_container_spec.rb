# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnK8s::CopyTextToFileInContainer' do

  let(:webservice) { double("Webservice") }
  let(:pod_namespace) { "PodNamespace" }
  let(:pod_name) { "PodName" }
  let(:container) { "Container" }
  let(:path) { "path/to/file" }
  let(:content) { "Content" }
  let(:mode) { "Mode" }

  let(:execute_command_in_container) { double("ExecuteCommandInContainer") }

  let(:k8s_object_lookup_instance) { double("K8sObjectLookupInstance") }
  let(:k8s_object_lookup) do
    double('K8sObjectLookup').tap do |k8s_object_lookup|
      allow(k8s_object_lookup).to receive(:new)
        .with(webservice)
        .and_return(k8s_object_lookup_instance)
    end
  end

  before(:each) do
    allow(execute_command_in_container)
      .to receive(:call)
  end

  context "Calling CopyTextToFileInContainer" do
    subject do
      ::Authentication::AuthnK8s::CopyTextToFileInContainer.new(
        execute_command_in_container: execute_command_in_container,
        k8s_object_lookup:            k8s_object_lookup
      ).call(
        webservice:    webservice,
        pod_namespace: pod_namespace,
        pod_name:      pod_name,
        container:     container,
        path:          path,
        content:       content,
        mode:          mode
      )
    end

    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end

    expected_body = <<~BODY
          #!/bin/sh
          set -e

          cleanup() {
            rm -f "path/to/file.tmp"
          }
          trap cleanup EXIT

          set_file_content() {
            cat > "path/to/file.tmp" <<EOF
          Content
          EOF

            chmod "Mode" "path/to/file.tmp"
            mv "path/to/file.tmp" "path/to/file"
          }

          set_file_content > "${TMPDIR:-/tmp}/conjur_copy_text_output.log" 2>&1
    BODY

    it "calls execute_command_in_container with expected parameters" do
      expect(execute_command_in_container)
        .to receive(:call)
          .with(
            hash_including(
              k8s_object_lookup: k8s_object_lookup_instance,
              pod_namespace:     pod_namespace,
              pod_name:          pod_name,
              container:         container,
              cmds:              %w[sh],
              body:              expected_body,
              stdin:             true
            )
          )
      subject
    end
  end
end
