def random_hex nbytes = 12
  @random ||= Random.new
  @random.bytes(nbytes).unpack('h*').first
end
