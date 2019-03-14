# frozen_string_literal: true

require 'spec_helper'

describe ::CA::SSH::Certificate do
 
  describe '#render' do
    let(:certificate_formatted) { "ssh-rsa-cert-v01@openssh.com AAAAHHNzaC1yc2EtY2VydC12MDFAb3BlbnNzaC5jb20AAAAg04p5e5un6zY7xSYUcee+mskS8k22xypXz1ojUYlv8kgAAAADAQABAAABAQDK5sTtOMTuVzX6GaRhQAYU2jS+PZHnAp8GFl/KSHa1WqWheQjqlazusddmpN5AEnuIFi3AJpSW186vJqq/yG8btYWqJcFEZnw+dA/klpNrdmLuFJnmDnBdDmOFX+/SDaQtN6zN/LvPW0xb23EIFZG+mPWmA2Kx7KY6cLtvyxFmKDk+c5zSuExNy4kBqNuuiAQGnwTRWoHcL/vLBw3xRiVeAqInIr1AXAVWD8v8G/h0+1pjia6ghBDMe1cf8DrCRzi+4KP2+MioLWsPUxthA60vLfOr8qd6Hp/BTU/S0qwExtQQ5wESbwEEyanyYHtDOw3hZrxa5Fk4nGqJxC9I3a3TAAAAAAAAAAAAAAABAAAABnNzaF9jYQAAAAAAAAAAXH/BewAAAABegep7AAAAAAAAAIIAAAAVcGVybWl0LVgxMS1mb3J3YXJkaW5nAAAAAAAAABdwZXJtaXQtYWdlbnQtZm9yd2FyZGluZwAAAAAAAAAWcGVybWl0LXBvcnQtZm9yd2FyZGluZwAAAAAAAAAKcGVybWl0LXB0eQAAAAAAAAAOcGVybWl0LXVzZXItcmMAAAAAAAAAAAAAARcAAAAHc3NoLXJzYQAAAAMBAAEAAAEBAMrmxO04xO5XNfoZpGFABhTaNL49kecCnwYWX8pIdrVapaF5COqVrO6x12ak3kASe4gWLcAmlJbXzq8mqr/Ibxu1haolwURmfD50D+SWk2t2Yu4UmeYOcF0OY4Vf79INpC03rM38u89bTFvbcQgVkb6Y9aYDYrHspjpwu2/LEWYoOT5znNK4TE3LiQGo266IBAafBNFagdwv+8sHDfFGJV4CoicivUBcBVYPy/wb+HT7WmOJrqCEEMx7Vx/wOsJHOL7go/b4yKgtaw9TG2EDrS8t86vyp3oen8FNT9LSrATG1BDnARJvAQTJqfJge0M7DeFmvFrkWTicaonEL0jdrdMAAAEPAAAAB3NzaC1yc2EAAAEARothdwmhbGLfYdS/BazJAGPX7rMAJaqccOnoUmCN89eNyJb5KV0VY+EZc8MVurhCyGN/oiPaY5YVQqD4ny6Jr5azShwotdVXy11FtP4y9WJ4rWmkV5CUS+HSh3EjMYrfOHMmKBd1IkXRzBN+l1J27wCCDjgHJlz3hapJsldaV5XvFGwhRZvUwOWU1Zudq9JNEIVcbB9b/zz5d7+ckc4EeOF9laJ74cyaWmatjO+2uP12vw+FE+poaCNTFg9bd/5g1/Noz9lETFHEHIp/p6MoyQilqo6O2fmHhbZsYcdLMOJmKcdOZItuAlKVyVEOHE2Mz6Sw/UtwBNVKy7oUhEUCFg==" }
    let(:certificate) do
      Net::SSH::KeyFactory.load_data_public_key(certificate_formatted)
    end

    subject { ::CA::SSH::Certificate.new(certificate: certificate).to_formatted }

    it "renders an SSH certificate to OpenSSH format" do
      expect(subject.to_s).to eq(certificate_formatted)
    end

    it "returns a content type of 'application/x-openssh-file" do
      expect(subject.content_type).to eq('application/x-openssh-file')
    end
  end
end
