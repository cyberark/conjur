Rails.application.routes.draw do
  mount ConjurAudit::Engine => "/conjur_audit"
end
