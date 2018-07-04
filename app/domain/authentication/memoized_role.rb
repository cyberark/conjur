# frozen_string_literal: true

module Authentication

  class MemoizedRole
    def self.[](role_id)
      @user_roles ||= Hash.new { |h, id| h[id] = Role[id] }
      @user_roles[role_id]
    end

    def self.roleid_from_username(account, username)
      Role.roleid_from_username(account, username)
    end
  end

end
