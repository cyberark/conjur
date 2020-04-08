# frozen_string_literal: true

require 'spec_helper'

describe StatusController, :type => :controller do
  describe "GET #index" do
    it 'renders the index template' do
      get :index
      expect(response).to render_template("index")
    end

    context 'with rendered views' do
      render_views

      it 'has the standard message' do
        get :index
        expect(response.body).to include('is running!')
      end

      it 'includes the version' do
        get :index
        expect(response.body).to include(
          "Version #{ENV["CONJUR_VERSION_DISPLAY"]}".strip
        )
      end
    end
  end
end
