# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Rotation::MasterRotator') do
  describe "#rotate_all" do
    it "successfully performs no rotations when there are no scheduled rotations" do
      master_rotator = Rotation::MasterRotator.new(avail_rotators: [])
      master_rotator.rotate_all
    end
    xit "successfully rotates each scheduled rotation" do
    end
  end
end
