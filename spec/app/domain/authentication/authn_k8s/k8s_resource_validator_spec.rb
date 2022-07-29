# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::K8sResourceValidator) do
  let(:log_output) { StringIO.new }
  let(:logger) {
    Logger.new(
      log_output,
      formatter: proc do | severity, time, progname, msg |
        "#{severity},#{msg}\n"
      end)
  }

  subject {
    described_class.new(k8s_object_lookup: k8s_object_lookup, pod: pod, logger: logger)
  }

  let(:k8s_object_lookup) {
    double("k8s_object_lookup").tap { |d|
      allow(d).to receive(:namespace_labels_hash)
        .with("namespace_name")
        .and_return({ :key1 => "value1", :key2 => "value2" })
    }
  }

  let(:pod) {
    double("pod").tap { |d|
      d.stub_chain("metadata.namespace").and_return("namespace_name")
    }
  }

  context "#valid_namespace?" do
    it 'raises error on empty label selector' do
      expect { subject.valid_namespace?(label_selector: "") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::InvalidLabelSelector
        )
      )
    end

    it 'raises error on invalid label selector' do
      # No key-value pair
      expect { subject.valid_namespace?(label_selector: "key,") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::InvalidLabelSelector
        )
      )

      # Unsupported operator
      expect { subject.valid_namespace?(label_selector: "key!=value") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::InvalidLabelSelector
        )
      )
    end

    it 'returns true for labels matching label-selector' do
      # Single key, single equals format
      expect(
        subject.valid_namespace?(label_selector: "key1=value1")
      ).to be true
      # Single key, double equals format
      expect(
        subject.valid_namespace?(label_selector: "key2==value2")
      ).to be true
      # Multiple keys
      expect(
        subject.valid_namespace?(label_selector: "key1=value1,key2=value2")
      ).to be true
    end

    it 'throws an error for labels not matching label-selector' do
      # Value mismatch
      expect { subject.valid_namespace?(label_selector: "key1=notvalue") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::LabelSelectorMismatch
        )
      )
      # Key not found
      expect { subject.valid_namespace?(label_selector: "notfoundkey=value") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::LabelSelectorMismatch
        )
      )
      # One of multiple keys does not match
      expect { subject.valid_namespace?(label_selector: "key1=value1,notfoundkey=value") }.to(
        raise_error(
          ::Errors::Authentication::AuthnK8s::LabelSelectorMismatch
        )
      )
    end

    it 'logs before label-selector validation begins, and after success' do
      subject.valid_namespace?(label_selector: "key1=value1")

      expect(log_output.string.split("\n")).to include(
        "DEBUG,CONJ00145D Validating K8s resource using label selector. Type:'namespace', Name:'namespace_name', Label:'key1=value1'",
        "DEBUG,CONJ00146D Validated K8s resource using label selector. Type:'namespace', Name:'namespace_name', Label:'key1=value1'"
      )
    end

    it 'logs before label-selector validation begins, but not after failure' do
      expect { subject.valid_namespace?(label_selector: "key1=notvalue") }.to raise_error

      expect(log_output.string.split("\n")).to include(
        "DEBUG,CONJ00145D Validating K8s resource using label selector. Type:'namespace', Name:'namespace_name', Label:'key1=notvalue'",
      )
      expect(log_output.string.split("\n")).not_to include(
        "DEBUG,CONJ00146D Validated K8s resource using label selector. Type:'namespace', Name:'namespace_name', Label:'key1=notvalue'"
      )
    end
  end
end
