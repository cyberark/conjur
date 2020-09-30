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

  let(:kubectl_exec) { double("KubectlExec") }

  let(:k8s_object_lookup_instance) { double("K8sObjectLookupInstance") }
  let(:k8s_object_lookup) { double("K8sObjectLookup") }
  let(:k8s_object_lookup) do
    double('k8s_object_lookup').tap do |k8s_object_lookup|
      allow(k8s_object_lookup).to receive(:new)
        .with(webservice)
        .and_return(k8s_object_lookup_instance)
    end
  end

  before(:each) do
    allow(kubectl_exec)
      .to receive(:call)
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Calling CopyTextToFileInContainer" do
    subject do
      ::Authentication::AuthnK8s::CopyTextToFileInContainer.new(
        kubectl_exec:      kubectl_exec,
        k8s_object_lookup: k8s_object_lookup
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

    expected_body = "\n#!/bin/sh\n" \
                    "set -e\n\n" \
                    "cleanup() {\n" \
                    "  rm -f \"path/to/file.tmp\"\n" \
                    "}\n" \
                    "trap cleanup EXIT\n\n" \
                    "set_file_content() {\n" \
                    "  cat > \"path/to/file.tmp\" <<EOF\nContent\nEOF\n\n" \
                    "  chmod \"Mode\" \"path/to/file.tmp\"\n" \
                    "  mv \"path/to/file.tmp\" \"path/to/file\"\n" \
                    "}\n\n" \
                    "set_file_content > \"${TMPDIR:-/tmp}/conjur_set_file_content.log\" 2>&1\n"

    it "calls kubectl_exec with expected parameters" do
      expect(kubectl_exec)
        .to receive(:call)
          .with(
            hash_including(
              k8s_object_lookup: k8s_object_lookup_instance,
              pod_namespace:     pod_namespace,
              pod_name:          pod_name,
              container:         container,
              cmds:              %w(sh),
              body:              expected_body,
              stdin:             true
            )
          )
      subject
    end
  end
end
