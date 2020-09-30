# frozen_string_literal: true

require 'command_class'

# SetFileContentInContainer is used to set some text into a file inside a container
module Authentication
  module AuthnK8s

    CopyTextToFileInContainer ||= CommandClass.new(
      dependencies: {
        kubectl_exec:      KubectlExec.new,
        k8s_object_lookup: K8sObjectLookup,
        logger:            Rails.logger
      },
      inputs: %i(webservice pod_namespace pod_name container path content mode)
    ) do

      LOG_FILE = "${TMPDIR:-/tmp}/conjur_set_file_content.log"

      def call
        copy_text_to_file_in_container
      end

      private

      def copy_text_to_file_in_container
        @kubectl_exec.call(
          k8s_object_lookup: @k8s_object_lookup.new(@webservice),
          pod_namespace:     @pod_namespace,
          pod_name:          @pod_name,
          container:         @container,
          cmds:              %w(sh),
          body:              set_file_content_script(@path, @content, @mode),
          stdin:             true
        )
      end

      # Sets the content of a file in a given path to the given content
      # We first copy the content into a temporary file and only then move it to
      # the desired path as the client polls on its existence and we want it to
      # exist only when the whole content is present.
      #
      # We redirect the output to a log file on the authn-client container
      # that will be written in its logs for supportability.
      def set_file_content_script(path, content, mode)
        tmp_cert = "#{path}.tmp"

        "
#!/bin/sh
set -e

cleanup() {
  rm -f \"#{tmp_cert}\"
}
trap cleanup EXIT

set_file_content() {
  cat > \"#{tmp_cert}\" <<EOF
#{content}
EOF

  chmod \"#{mode}\" \"#{tmp_cert}\"
  mv \"#{tmp_cert}\" \"#{path}\"
}

set_file_content > \"#{LOG_FILE}\" 2>&1
"
      end
    end
  end
end
