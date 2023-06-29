# frozen_string_literal: true

require 'spec_helper'

describe PolicyTemplates::TemplatesRenderer do

  subject(:controller) { Controller.new }

  context "Template works" do

    it "run" do
      value = controller.send(:show)
      expect(value).to include("test")
    end

  end

  class Controller
    include PolicyTemplates::TemplatesRenderer

    def show
      renderer(template, input)
    end

    def template
      FakeTemplate.new
    end

    def input
      {
        "id" => "test"
      }
    end
  end

  class FakeTemplate < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        <%= id %>
      TEMPLATE
    end
  end

end