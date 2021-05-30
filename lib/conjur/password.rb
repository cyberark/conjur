module Conjur
  # Enable password validation
  module Password
    # special characters according to https://www.owasp.org/index.php/Password_special_characters
    VALID_PASSWORD_REGEX = %r{^(?=.*?[A-Z].*[A-Z]) # 2 uppercase letters
      (?=.*?[a-z].*[a-z])                                 # 2 lowercase letters
      (?=.*?[0-9])                                        # 1 digit
      (?=.*[ !"#$%&'()*+,-./:;<=>?@\[\\\]^_`{|}~]).      # 1 special character
      {12,128}$}x.freeze                                  # 12-128 characters

    def self.valid?(pwd)
      # If password is nil it will be coerced to be empty string
      string_pwd = String(pwd)
      return false if string_pwd.include?("\n")
      
      string_pwd.match?(VALID_PASSWORD_REGEX)
    end
  end
end
