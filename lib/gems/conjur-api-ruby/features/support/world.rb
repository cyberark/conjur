module ApiWorld
  def last_json
    @result.to_json
  end

  def random_hex nbytes = 12
    @random ||= Random.new
    @random.bytes(nbytes).unpack('h*').first
  end
end

World ApiWorld
