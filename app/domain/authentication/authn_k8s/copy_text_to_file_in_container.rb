# frozen_string_literal: true

require 'command_class'

# SetFileContentInContainer is used to set some text into a file inside a container
module Authentication
  module AuthnK8s

    CopyTextToFileInContainer = CommandClass.new(
      dependencies: {
        execute_command_in_container: ExecuteCommandInContainer.new,
        k8s_object_lookup: K8sObjectLookup,
        logger: Rails.logger
      },
      inputs: %i[webservice pod_namespace pod_name container path content mode]
    ) do
      LOG_DIR = "${TMPDIR:-/tmp}"
      LOG_FILE = "#{LOG_DIR}/conjur_copy_text_output.log"

      def call
        copy_text_to_file_in_container
      end

      private

      def copy_text_to_file_in_container
        @execute_command_in_container.call(
          k8s_object_lookup: @k8s_object_lookup.new(@webservice),
          pod_namespace: @pod_namespace,
          pod_name: @pod_name,
          container: @container,
          cmds: %w[sh],
          body: bash_script(@path, @content, @mode),
          stdin: true
        )
      end

      # Sets the content of a file in a given path to the given content
      # We first copy the content into a temporary file and only then move it to
      # the desired path as the client polls on its existence and we want it to
      # exist only when the whole content is present.
      #
      # We redirect the output to a log file on the authn-client container
      # that will be written in its logs for supportability.
      def bash_script(path, content, mode)
        tmp_cert = "#{path}.tmp"

        <<~BASH_SCRIPT
          #!/bin/sh
          set -e

          cleanup() {
            rm -f "#{tmp_cert}"
          }
          trap cleanup EXIT

          set_file_content() {
            cat > "#{tmp_cert}" <<EOF
          #{content}
          EOF

            chmod "#{mode}" "#{tmp_cert}"
            mv "#{tmp_cert}" "#{path}"
          }

          # Check if log directory is writeable before attempting to log
          if [ -w "#{LOG_DIR}" ]; then
            set_file_content > "#{LOG_FILE}" 2>&1
          else
            # Still perform the operation but echo warning to stderr
            echo "WARNING: Log directory '#{LOG_DIR}' is not writeable. Certificate will be injected but operation logs will not be saved." >&2
            set_file_content
          fi
        BASH_SCRIPT
      end
    end
  end
end
