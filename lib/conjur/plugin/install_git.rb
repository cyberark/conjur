require 'forwardable'

module Conjur
  module Plugin
    class InstallGit
      extend Forwardable

      def initialize(
        git_clone_root: '/tmp',
        plugin_install_dir: './plugins/installed'
      )
        @git_clone_root = git_clone_root
        @plugin_install_dir = plugin_install_dir
      end

      def call(repository:, branch: nil, directory: nil)
        @repository = repository
        @branch = branch
        @directory = directory

        checkout_git_repository
        build_gem
        install_gem
      ensure
        cleanup_git_checkout
      end

      private

      def checkout_git_repository
        `git clone#{git_branch_argument} "#{@repository}" "#{git_clone_path}"`
      end

      def cleanup_git_checkout
        return unless Dir.exist?(git_clone_path)

        FileUtils.rm_rf(git_clone_path)
      end

      def git_branch_argument
        return nil unless @branch

        " --branch '#{branch}'"
      end

      def git_clone_path
        File.join(@git_clone_root, repository_name)
      end

      def repository_name
        @repository_name ||= URI(@repository).path.split('/').last
      end

      def build_gem
        # Change directory to the git checkout
        Dir.chdir(git_clone_path) do
          `gem build '#{name}.gemspec'`
        end
      end

      def name
        gem_spec.name
      end

      def version
        gem_spec.version
      end

      def gem_spec
        @gem_spec ||= Gem::Specification.load(gem_spec_path)
      end

      def gem_spec_path
        @gem_spec_path ||= Dir["#{git_clone_path}/*.gemspec"].first.to_s
      end

      def install_gem
        # Ensure parent directory exists
        FileUtils.mkdir_p(@plugin_install_dir)

        `gem install "#{gemfile}" --install-dir '#{@plugin_install_dir}'`
      end

      def gemfile
        File.join(git_clone_path, "#{name}-#{version}.gem")
      end
    end
  end
end
