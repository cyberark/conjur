# frozen_string_literal: true

# Rotators:
#
# - live under a submodule of Rotation::Rotators (eg, Rotation::Rotators::AWS)
# - are named XXXRotator
# - multiple rotators can live under a single Rotation::Rotators submodule 
#   (eg, if AWS had multiple kinds of rotators)
#

# Ensure the rotator files have been loaded
#
Dir[File.join("./app/domain/rotation/rotators/*/", "*.rb")].sort.each do |f|
  require f
end

module Rotation
  class InstalledRotators

    def self.new(rotators_module: ::Rotation::Rotators)
      ::Util::Submodules.of(rotators_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
        .select { |cls| ::Rotation::RotatorClass::Validation.new(cls).valid? }
        .map { |cls| ::Rotation::RotatorClass.new(cls) }
        .map { |cls| [cls.annotation_name, cls.instance] }
        .to_h
    end

  end
end
