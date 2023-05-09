# frozen_string_literal: true

require 'spec_helper'

describe HealthController, :type => :controller do
  describe "GET health" do
    it 'renders the health route sanity' do
      get :health
      expect(response.code).to eq("200")
    end

    context "negative" do
      it 'renders the health route fails' do
        expect_any_instance_of(HealthController).to receive(:check_db_connection).and_return(false)
        get :health
        expect(response.code).to eq("503")
      end
    end

  end
end
