require "simplecov"
require "simplecov-cobertura"

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
SimpleCov.start

require 'slosilo'

shared_context "with mock adapter" do
  require 'slosilo/adapters/mock_adapter'

  let(:adapter) { Slosilo::Adapters::MockAdapter.new }
  before { Slosilo::adapter = adapter }
end

shared_context "with example key" do
  let(:rsa) { OpenSSL::PKey::RSA.new """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAtTG/SQhW9QawP+GL6EZ5Al9gscCr7HiRO7MuQqFkaXIJD6+3
prdHRrb0qqjNlGFgDBGAuswZ2AYqhBt7eekup+/vIpI5n04b0w+is3WwZAFco4uP
ojDeM0aY65Ar3Zgra2vWUJXRwBumroZjVBVoLJSgVfwIhwU6ORbS2oJflbtqxpuS
zkPDqS6RwEzI/DHuHTOI26fe+vfuDqGOuSR6iVI16lfvTbWwccpDwU0W9vSlyjjD
LIw0MnoKL3DHyzO66s+oNNRleMvjghQtJk/xg1kRuHReJ5/ygt2zyzdKSLeqU+T+
TCWw/F65jrFElftexiS+g+lZC467VLCaMe1fJQIDAQABAoIBAQCiNWzXRr4CEQDL
z3Deeehu9U+tEZ1Xzv/FgD0TrUQlGc9+2YIBn+YRKkySUxfnk9zWMP0bPQiN2cdK
CQhbNSNteGCOhHVNZjGGm2K+YceNX6K9Tn1BZ5okMTlI+QIsGMQWIK316omh/58S
coCNj7R45H09PKmtpkJfRU1yDHDhqypjPDpb9/7U5mt3g2BdXYi+1hilfonHoDrC
yy3eRdf7Tlij9O3UeM+Z7pZrKATcvpDkYbNWizDITvKMYy6Ss+ajM5v7lt6QN5LP
MHjwX8Ilrxkxl0jeopr4f94tR7rNDZbLC457j8gns7cUeODtF7pPZqlrlk4KOq8Q
DvEMt2ZpAoGBAOLNUiO1SwRo75Y8ukuMVQev8O8WuzEEGINoM1lQiYlbUw3HmVp3
iUvv58ANmKSzTXpOEZ1L8pZHSp435FrzD2WZmCAoXhNdfAXtmZA7Y46iE6BF4qrr
UegtLPhVgwpO74Y+4w2YwfDknzCOhWE4sxCbukuSvxz2pz1Vm31eFB6jAoGBAMyF
VxfYq9WhmLNsHqR+qfhb1EC5FfpSq23z/o4ryiKqCaWHimVtOO7DL7x2SK3mVNNZ
X8b4+vnJpAQ3nOxeg8fpmBaLAWYRna2AN/CYVIMKYusawhsGAlZZTu2mtJKLiOPS
8/z5dK55xJWlG5JalUB+n/4vd3WmXiT/XJj3qU+XAoGBALyHzLXeKCPcTvzmMj5G
wxAG0xMMJEMUkoP5hGXEKvBBOAMGXpXzM/Ap1s2w/6g5XDhE2SOWVGtTi9WFxI9N
6Qid6vUgWUNjvIr4/WQF2jZgyEu8jDVkM8v6cZ1lB+7zuuwvLnLI/r6ObT3h20H7
7e3qZawYqkEbT94OYZiPMc5dAoGAHmIQtjIyFOKU1NLTGozWo1bBCXx1j2KIpSUC
RAytUsj/9d9U6Ax50L6ecNkBoxP8tgko+V4zqrgR7a51WYgQ+7nwJikwZAFp80SB
CvUWWQFKALNQ8sLJxhouZ4/Ec6DXDUFhjcthUio00iZdGjjqw1IMYq6aiJfWlJh7
IR5pwLECgYEAyjlguks/3cjrHRF+yjonxT4tLuBI/n3TAQUPqmtkJtcwZSAJas/1
c/twlAJ7F6n3ZroF3lgPxMJRRHZl4Z4dJsDatIxVShf3nSGg9Mi5C25obxahbv5/
Dg1ikwi8GUF4HPZe9DyhXgDhg19wM/qcpjX8bSypsUWHWP+FanhjdWU=
-----END RSA PRIVATE KEY-----
        """ }
  let (:key) { Slosilo::Key.new rsa.to_der }
  let (:key_fingerprint) { "107bdb8501c419fad2fdb20b467d4d0a62a16a98c35f2da0eb3b1ff929795ad9" }

  let (:another_rsa) do
    OpenSSL::PKey::RSA.new """
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAryP0uGEIcDFmHDj1MjxbW+eWMeQ1k2FTKI7qx2M3MP9FR3Bz
KjFzGKnAA6QV46K/QtEt+wpWedB/bcikPXY4/vh/b2TEi8Ybw2ztT1oW9le8Djsz
3sQv5QrHsOXzSIARw4NZYxunxMFKCVC9jA8tXJb16RLgS3wAOMiPADlWIKEmPIX6
+hg2PDgFcrCuL3XAwJ4GKy3Q5BpIFF2j+wRNfjCXDFf1bU9Gy9DND8Y50Khhw/Zn
GYN1Y3AZ3YPzz1SPf08WM663ImYwORjdkA5VlIAMKcmSStNZZUrCOo7DQjNZVD2O
vfGhGUlPqYkmTPnCG2aNP8aJm3IbF+Cb6N6PjwIDAQABAoIBAEaYtr9PlagrsV40
81kxjR3pptgrhhEHTQ7vNOH0Mz4T16gpQrLCRgOuARE2pgAhDPlw+hjUHPFzQrpN
Ay8nJWhZYHzVYIh67ZwDn1C6HsFjshEGei0UZb3sb3v15O/Xd9GYc4KIlkKwKxjA
K/d18rH8w9kUW8bxj+FTrpjHg9kYkWGjl1WUM4o4dALVVAbbILCHKUIv3wmU5Off
oqBDunItrfVvvc9UOt1SMO15fwuZZpk0B5cjjo6+1NNpIOzqnuu48iI5dQRAIr50
n44U4/Ix4E1p4i/9i5trCeSZRMrVxBruNxFBtCeDU6YW5fXYNBLptndfb83iqSJf
46myqakCgYEA2MAsbtOcvQv+C7KsRMQih4WqpybV/TRdeC+dZ3flPvSuI8VLJAHp
p2Tp3WXATCwgUWL/iktwWE7WFMn3VvAuMm2ITmAze/Uk71uUS5R+iaGIeRXHgd9J
fyJrIeD63ncWbb23rif2sO6zH4cp9NLS/OopHiRNlRsWEUoGpybxczMCgYEAztrf
mX4oqjqk4af4o4/UHVp3Y9lpcUXRi6dYYECoqv6wS7qCIbJkD4I4P6oTwvk25vbk
p9fwOttuqHC53/rDXVjedNe9VExIe5NhVaug1SyArw/qsafYs0QeDRBkSgCcLfP6
LP4g824Wbv52X33BO0rJbDCICDqGDCOkqB4XcjUCgYBCkcMTxqo85ZIAxb9i31o7
hTIEZEkUmyCZ6QXO4WPnEf7pvY52YKACaVvqQ3Xr7yF93YneT40RkiTt/ZmZeeq2
Ui2q5KDrUT8mxFmnXNQAMTxY8/dyS8Gm6ks8/HwQF0MsMThYpK1/adBZvomER7vF
MaWvPDcXtFnytWmVrMA7QQKBgQDIHpHR4m6e+atIMIPoYR5Z44q7i7tp/ZzTGevy
+rry6wFN0jtRNE9/fYDDftwtdYL7AYKHKu7bUi0FQkFhAi39YhudOJaPNlmtTBEP
m8I2Wh6IvsJUa0jHbbAQ/Xm46kwuXOn8m0LvnuKPMRj+GyBVJ24kf/Mq2suSdO04
RBx0vQKBgFz93G6bSzmFg0BRTqRWEXEIuYkMIZDe48OjeP4pLYH9aERsL/f/8Dyc
X2nOMv/TdLP7mvGnwCt/sQ2626DdiNqimekyBki9J2r6BzBNVmEvnLAcYaQAiQYz
ooQ2FuL0K6ukQfHPjuMswqi41lmVH8gIVqVC+QnImUCrGxH9WXWy
-----END RSA PRIVATE KEY-----
    """
  end

  def self.mock_own_key
    before { allow(Slosilo).to receive(:[]).with(:own).and_return key }
  end
end
