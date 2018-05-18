# Rotators:
#
# - live under a submodule of Rotation::Rotators (eg, Rotation::Rotators::AWS)
# - are named XXXRotator
# - multiple rotators can live under a single Rotation::Rotators submodule 
#   (eg, if AWS had multiple kinds of rotators)
#
module Rotation
  class InstalledRotators

    def self.new(rotators_module: ::Rotation::Rotators)
      ::Util::Submodules.of(rotators_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
        .select { |cls| valid?(cls) }
        .map { |cls| [annotation_name(cls), cls.new] }
        .to_h
    end

    private

    # The "annotation_name" is how the name of the rotator used in policy.yml,
    # as a variable annotation.
    #
    def self.annotation_name(rotator)
      ::Rotation::RotatorClass.new(rotator).annotation_name
    end

    def self.valid?(cls)
      ::Rotation::RotatorClass::Validation.new(cls).valid?
    end

  end
end
