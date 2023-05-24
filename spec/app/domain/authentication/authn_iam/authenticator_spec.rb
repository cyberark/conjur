# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnIam::Authenticator) do
  let(:authenticator) { Authentication::AuthnIam::Authenticator.new(env:[]) }
  let(:conjur_role) { 'host/foo/188945769008/conjur-role' }

  # Good headers
  let(:valid_global_headers) { '{"host":"sts.amazonaws.com","x-amz-date":"20230518T152525Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDcaDGV1LWNlbnRyYWwtMSJGMEQCIB7Inb5Q2L+Tu0nDM6KpYkqjXetnd6Eizw9gt3c27+okAiBJHE59aL6HuIszrEmk7/SaclqSmEZ5xUmEJ10Hla8PYyq8BQhgEAMaDDE4ODk0NTc2OTAwOCIMg1WLlzrcLY1FHaQKKpkFcEmdxNL2sGdxHOhoLv5hf0pQsOhWciwMgGhGpSUM7gXSG6Z8Rqv7q1rqgl04BjxLZshOOJYdIfUjUNccgiWBofjRYNH5SGeuLuu7XfrtmGmToPSejG5vY76PFXyef4bRNpgkB2aTRjRIg/fInQF0y2oILUSbX4nUcvcJJpss7VnpGRgGqGE+HtatAnfAn0cVoPHs/I2oZslP9y2IVVAEbCxKhYUcHniCJzrmTrppczyd8bwC36wdhcN88YtUES3Z0sS9Ho3JcLbxeAnoqkuPng1VYLAt5uELOqqYWSsdqVFwc+PJ5JoBAJSab1dyPp/YhTg+Lp8pYm/cgSR4lygqgeElL+30tI77GFuMdxdnWymk1mvXtcr0Q/eOMpAETohivAEW+m4CglAEF3VTdLQXODKCvxsiUmsN5AanX7eKGeHPfy/mcM/srWWkVNeRk//DLFNSgfiaeBQeUpzRDEgVpweA4tf5xjW8oUxp9hK9Q872dxgye07bFLNXbyqK9NPAGIcD4/7Tw73kPxYSvZ+7wajgkGdcuIz91GR973QG2k5e82PwiiROOm8qEJo7QzPX6hF5s//qSnKr0vGo4tBrewKvQVjhafdf+B0b44jgw7kIsUkAYz/1HY2PPQVvVn5DayO7VxCTTd+VrQScr22ExOucIKEw30j5hCkhRnUMS6MAjsYwclSbPuUeZ8rVvFQSEoC37SQZP13OVphFNUUFVhZJU5kYd9BvaFhPO0F54XJq1Gu/biMJFumHj2lz5TadSXxyJwSJkfqE53B9b6Sc1RB7O4AckozmH/pm46fJpD5sq7RLQg9YLA//fi+EoBwqbiskCz7WRsCh/Q2l/dmA9kAPPVatqkagVdcJKAJNl8W4Y9nm9MBhdFIw4PeYowY6sgF2td8Xkg0E4ClmQ3CoGWO+TTWmiWwN0BAcKD5prq3V9qmn3SXnzLUO02k0gC4RsdGUCSiByzNHL3mG+G7l8MEZ8TmZQ+ZCgtlnvLYsdECiT+7tcrwN8Zpiu0BKcAWSV8Mg5/D0HYfDTFAv7jgqXuL+uruLJw4xzZCoWc5Ru1Mhprl4NF8T9Am2RyEEEO9rjveQCWpzaZmyvx/MS4isoqhC2KGeJEyeulk2XE0mXO6TZz9c","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGDI4QX56/20230518/us-east-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=81b929060b45f05470c9f542a9e46cdce51d37c1d22a58d1942b7fa175079af5"}' }
  let(:valid_regional_headers) { '{"host":"sts.eu-central-1.amazonaws.com","x-amz-date":"20230518T152442Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDcaDGV1LWNlbnRyYWwtMSJGMEQCIB7Inb5Q2L+Tu0nDM6KpYkqjXetnd6Eizw9gt3c27+okAiBJHE59aL6HuIszrEmk7/SaclqSmEZ5xUmEJ10Hla8PYyq8BQhgEAMaDDE4ODk0NTc2OTAwOCIMg1WLlzrcLY1FHaQKKpkFcEmdxNL2sGdxHOhoLv5hf0pQsOhWciwMgGhGpSUM7gXSG6Z8Rqv7q1rqgl04BjxLZshOOJYdIfUjUNccgiWBofjRYNH5SGeuLuu7XfrtmGmToPSejG5vY76PFXyef4bRNpgkB2aTRjRIg/fInQF0y2oILUSbX4nUcvcJJpss7VnpGRgGqGE+HtatAnfAn0cVoPHs/I2oZslP9y2IVVAEbCxKhYUcHniCJzrmTrppczyd8bwC36wdhcN88YtUES3Z0sS9Ho3JcLbxeAnoqkuPng1VYLAt5uELOqqYWSsdqVFwc+PJ5JoBAJSab1dyPp/YhTg+Lp8pYm/cgSR4lygqgeElL+30tI77GFuMdxdnWymk1mvXtcr0Q/eOMpAETohivAEW+m4CglAEF3VTdLQXODKCvxsiUmsN5AanX7eKGeHPfy/mcM/srWWkVNeRk//DLFNSgfiaeBQeUpzRDEgVpweA4tf5xjW8oUxp9hK9Q872dxgye07bFLNXbyqK9NPAGIcD4/7Tw73kPxYSvZ+7wajgkGdcuIz91GR973QG2k5e82PwiiROOm8qEJo7QzPX6hF5s//qSnKr0vGo4tBrewKvQVjhafdf+B0b44jgw7kIsUkAYz/1HY2PPQVvVn5DayO7VxCTTd+VrQScr22ExOucIKEw30j5hCkhRnUMS6MAjsYwclSbPuUeZ8rVvFQSEoC37SQZP13OVphFNUUFVhZJU5kYd9BvaFhPO0F54XJq1Gu/biMJFumHj2lz5TadSXxyJwSJkfqE53B9b6Sc1RB7O4AckozmH/pm46fJpD5sq7RLQg9YLA//fi+EoBwqbiskCz7WRsCh/Q2l/dmA9kAPPVatqkagVdcJKAJNl8W4Y9nm9MBhdFIw4PeYowY6sgF2td8Xkg0E4ClmQ3CoGWO+TTWmiWwN0BAcKD5prq3V9qmn3SXnzLUO02k0gC4RsdGUCSiByzNHL3mG+G7l8MEZ8TmZQ+ZCgtlnvLYsdECiT+7tcrwN8Zpiu0BKcAWSV8Mg5/D0HYfDTFAv7jgqXuL+uruLJw4xzZCoWc5Ru1Mhprl4NF8T9Am2RyEEEO9rjveQCWpzaZmyvx/MS4isoqhC2KGeJEyeulk2XE0mXO6TZz9c","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGDI4QX56/20230518/eu-central-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=8e0bebec9a3ce860b4595a4b27710da558a157a711e2dcbfe3a86881af99c459"}' }

  # Bad headers
  let(:expired_headers) { '{"host":"sts.eu-central-1.amazonaws.com","x-amz-date":"20230518T152442Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDcaDGV1LWNlbnRyYWwtMSJGMEQCIB7Inb5Q2L+Tu0nDM6KpYkqjXetnd6Eizw9gt3c27+okAiBJHE59aL6HuIszrEmk7/SaclqSmEZ5xUmEJ10Hla8PYyq8BQhgEAMaDDE4ODk0NTc2OTAwOCIMg1WLlzrcLY1FHaQKKpkFcEmdxNL2sGdxHOhoLv5hf0pQsOhWciwMgGhGpSUM7gXSG6Z8Rqv7q1rqgl04BjxLZshOOJYdIfUjUNccgiWBofjRYNH5SGeuLuu7XfrtmGmToPSejG5vY76PFXyef4bRNpgkB2aTRjRIg/fInQF0y2oILUSbX4nUcvcJJpss7VnpGRgGqGE+HtatAnfAn0cVoPHs/I2oZslP9y2IVVAEbCxKhYUcHniCJzrmTrppczyd8bwC36wdhcN88YtUES3Z0sS9Ho3JcLbxeAnoqkuPng1VYLAt5uELOqqYWSsdqVFwc+PJ5JoBAJSab1dyPp/YhTg+Lp8pYm/cgSR4lygqgeElL+30tI77GFuMdxdnWymk1mvXtcr0Q/eOMpAETohivAEW+m4CglAEF3VTdLQXODKCvxsiUmsN5AanX7eKGeHPfy/mcM/srWWkVNeRk//DLFNSgfiaeBQeUpzRDEgVpweA4tf5xjW8oUxp9hK9Q872dxgye07bFLNXbyqK9NPAGIcD4/7Tw73kPxYSvZ+7wajgkGdcuIz91GR973QG2k5e82PwiiROOm8qEJo7QzPX6hF5s//qSnKr0vGo4tBrewKvQVjhafdf+B0b44jgw7kIsUkAYz/1HY2PPQVvVn5DayO7VxCTTd+VrQScr22ExOucIKEw30j5hCkhRnUMS6MAjsYwclSbPuUeZ8rVvFQSEoC37SQZP13OVphFNUUFVhZJU5kYd9BvaFhPO0F54XJq1Gu/biMJFumHj2lz5TadSXxyJwSJkfqE53B9b6Sc1RB7O4AckozmH/pm46fJpD5sq7RLQg9YLA//fi+EoBwqbiskCz7WRsCh/Q2l/dmA9kAPPVatqkagVdcJKAJNl8W4Y9nm9MBhdFIw4PeYowY6sgF2td8Xkg0E4ClmQ3CoGWO+TTWmiWwN0BAcKD5prq3V9qmn3SXnzLUO02k0gC4RsdGUCSiByzNHL3mG+G7l8MEZ8TmZQ+ZCgtlnvLYsdECiT+7tcrwN8Zpiu0BKcAWSV8Mg5/D0HYfDTFAv7jgqXuL+uruLJw4xzZCoWc5Ru1Mhprl4NF8T9Am2RyEEEO9rjveQCWpzaZmyvx/MS4isoqhC2KGeJEyeulk2XE0mXO6TZz9c","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGDI4QX56/20230518/eu-central-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=8e0bebec9a3ce860b4595a4b27710da558a157a711e2dcbfe3a86881af99c459"}' }
  let(:different_signing_request_uri) { '{"host":"sts.amazonaws.com","x-amz-date":"20230518T153130Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDcaDGV1LWNlbnRyYWwtMSJGMEQCIB7Inb5Q2L+Tu0nDM6KpYkqjXetnd6Eizw9gt3c27+okAiBJHE59aL6HuIszrEmk7/SaclqSmEZ5xUmEJ10Hla8PYyq8BQhgEAMaDDE4ODk0NTc2OTAwOCIMg1WLlzrcLY1FHaQKKpkFcEmdxNL2sGdxHOhoLv5hf0pQsOhWciwMgGhGpSUM7gXSG6Z8Rqv7q1rqgl04BjxLZshOOJYdIfUjUNccgiWBofjRYNH5SGeuLuu7XfrtmGmToPSejG5vY76PFXyef4bRNpgkB2aTRjRIg/fInQF0y2oILUSbX4nUcvcJJpss7VnpGRgGqGE+HtatAnfAn0cVoPHs/I2oZslP9y2IVVAEbCxKhYUcHniCJzrmTrppczyd8bwC36wdhcN88YtUES3Z0sS9Ho3JcLbxeAnoqkuPng1VYLAt5uELOqqYWSsdqVFwc+PJ5JoBAJSab1dyPp/YhTg+Lp8pYm/cgSR4lygqgeElL+30tI77GFuMdxdnWymk1mvXtcr0Q/eOMpAETohivAEW+m4CglAEF3VTdLQXODKCvxsiUmsN5AanX7eKGeHPfy/mcM/srWWkVNeRk//DLFNSgfiaeBQeUpzRDEgVpweA4tf5xjW8oUxp9hK9Q872dxgye07bFLNXbyqK9NPAGIcD4/7Tw73kPxYSvZ+7wajgkGdcuIz91GR973QG2k5e82PwiiROOm8qEJo7QzPX6hF5s//qSnKr0vGo4tBrewKvQVjhafdf+B0b44jgw7kIsUkAYz/1HY2PPQVvVn5DayO7VxCTTd+VrQScr22ExOucIKEw30j5hCkhRnUMS6MAjsYwclSbPuUeZ8rVvFQSEoC37SQZP13OVphFNUUFVhZJU5kYd9BvaFhPO0F54XJq1Gu/biMJFumHj2lz5TadSXxyJwSJkfqE53B9b6Sc1RB7O4AckozmH/pm46fJpD5sq7RLQg9YLA//fi+EoBwqbiskCz7WRsCh/Q2l/dmA9kAPPVatqkagVdcJKAJNl8W4Y9nm9MBhdFIw4PeYowY6sgF2td8Xkg0E4ClmQ3CoGWO+TTWmiWwN0BAcKD5prq3V9qmn3SXnzLUO02k0gC4RsdGUCSiByzNHL3mG+G7l8MEZ8TmZQ+ZCgtlnvLYsdECiT+7tcrwN8Zpiu0BKcAWSV8Mg5/D0HYfDTFAv7jgqXuL+uruLJw4xzZCoWc5Ru1Mhprl4NF8T9Am2RyEEEO9rjveQCWpzaZmyvx/MS4isoqhC2KGeJEyeulk2XE0mXO6TZz9c","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGDI4QX56/20230518/us-east-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=2f0162e0124dfeb105bc8a318efb93272797e2762a4fe93010437594a0d0244d"}' }
  let(:different_signing_request_verb) { '{"host":"sts.amazonaws.com","x-amz-date":"20230518T153042Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDcaDGV1LWNlbnRyYWwtMSJGMEQCIB7Inb5Q2L+Tu0nDM6KpYkqjXetnd6Eizw9gt3c27+okAiBJHE59aL6HuIszrEmk7/SaclqSmEZ5xUmEJ10Hla8PYyq8BQhgEAMaDDE4ODk0NTc2OTAwOCIMg1WLlzrcLY1FHaQKKpkFcEmdxNL2sGdxHOhoLv5hf0pQsOhWciwMgGhGpSUM7gXSG6Z8Rqv7q1rqgl04BjxLZshOOJYdIfUjUNccgiWBofjRYNH5SGeuLuu7XfrtmGmToPSejG5vY76PFXyef4bRNpgkB2aTRjRIg/fInQF0y2oILUSbX4nUcvcJJpss7VnpGRgGqGE+HtatAnfAn0cVoPHs/I2oZslP9y2IVVAEbCxKhYUcHniCJzrmTrppczyd8bwC36wdhcN88YtUES3Z0sS9Ho3JcLbxeAnoqkuPng1VYLAt5uELOqqYWSsdqVFwc+PJ5JoBAJSab1dyPp/YhTg+Lp8pYm/cgSR4lygqgeElL+30tI77GFuMdxdnWymk1mvXtcr0Q/eOMpAETohivAEW+m4CglAEF3VTdLQXODKCvxsiUmsN5AanX7eKGeHPfy/mcM/srWWkVNeRk//DLFNSgfiaeBQeUpzRDEgVpweA4tf5xjW8oUxp9hK9Q872dxgye07bFLNXbyqK9NPAGIcD4/7Tw73kPxYSvZ+7wajgkGdcuIz91GR973QG2k5e82PwiiROOm8qEJo7QzPX6hF5s//qSnKr0vGo4tBrewKvQVjhafdf+B0b44jgw7kIsUkAYz/1HY2PPQVvVn5DayO7VxCTTd+VrQScr22ExOucIKEw30j5hCkhRnUMS6MAjsYwclSbPuUeZ8rVvFQSEoC37SQZP13OVphFNUUFVhZJU5kYd9BvaFhPO0F54XJq1Gu/biMJFumHj2lz5TadSXxyJwSJkfqE53B9b6Sc1RB7O4AckozmH/pm46fJpD5sq7RLQg9YLA//fi+EoBwqbiskCz7WRsCh/Q2l/dmA9kAPPVatqkagVdcJKAJNl8W4Y9nm9MBhdFIw4PeYowY6sgF2td8Xkg0E4ClmQ3CoGWO+TTWmiWwN0BAcKD5prq3V9qmn3SXnzLUO02k0gC4RsdGUCSiByzNHL3mG+G7l8MEZ8TmZQ+ZCgtlnvLYsdECiT+7tcrwN8Zpiu0BKcAWSV8Mg5/D0HYfDTFAv7jgqXuL+uruLJw4xzZCoWc5Ru1Mhprl4NF8T9Am2RyEEEO9rjveQCWpzaZmyvx/MS4isoqhC2KGeJEyeulk2XE0mXO6TZz9c","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGDI4QX56/20230518/us-east-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=bd7f1e549999b6854adfb7c35e344efa38d74bac1c9078fbc34f71f4ff90173b"}' }
  let(:global_non_global_signer) { '{"host":"sts.amazonaws.com","x-amz-date":"20230518T155824Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDgaDGV1LWNlbnRyYWwtMSJIMEYCIQDQLBDLt5kNEEj40A2gX/kurzw9AAwYKnJIjQSrXGynmQIhAINJPoMDfHiSe6Bjzuwc9lwbe/iUPkVUUClFbUicPhNtKrwFCGEQAxoMMTg4OTQ1NzY5MDA4IgyYkP5L6wWxumObWPQqmQXd1mkF8hU1CCkhdJdc73vLVnGFvGbqru9SpzDIkbo0/syIZR7pjEoPTw/sUxFa/jYgcRrDh9bUmTBT7zU2/HDJRrwZfNgu9PPEtRGkIUOYri8muc0X8yLnHlk/5jvpwU5RY2uUoTZt+pvgm8jOHi/lkrtPx8uiQeEOeBkKe/DA2tFfHeVrC9OPkWQkjm0k9nsDggpwy9jf+RbzeSRb6Tyg4WWplDKW+a7VhBpBs1cNGGx9um590gpgpxaC93CIAtxI+iOxreH+xofhrJAPirms1yR4f5GD+glhr/mpCdclX0Eehvb+nxosnYKMh8XvlKR1GzP/PtqGCCRMpCByPmiXtotOMEQv96QGGs0/A8vdiktjJuGbjSQxKvw1UNG5Cxrb7DRqexPoILxoZAICSiFDK2vPPl2ePTWrk3MFxBKj+UK2VihhE1fpnZ7UXrVmQAUzNtDTdaaTcWy2ZTf4oAcRkUsYUl1BOIQYEcI0LmpCkqHb51ANbPO9bFxLAGTUuV9AMSRcrEojiFlxl+yiK5lPygJzrbRQBhnh3srxoHjfN5KvgVf0PqS3HUWIX/eknhBTJbhPO9d7me1/rTudqFd1dLEEiTJbN6KGF0vZvAgnahcoA4YSxLhG/EkNdOKbS/lJOUeysN/l/3L19RuWX9gd2Pc2FD7KWM6mzNAFIi8OAIChTnhZO7a6lcYZb+5uY+5N3Oh2Qthx7cc5k0DGQXX2FGYQgQKY9MWQo6s3Z2DwfNDddgYEM2clnnNPP+lNU7evdCsDb4/QPyDv+l14Tmdz2adhcsi4hkX9YGaCko6S6tdPI1fURyTkCKfUJ643ZNXyqmx4vRPupO2ukJArh7piCas8+B4FsScjD1sD3dH9aVwa2sI1tVed9zCclpmjBjqwATqNRvOZinA+mqThE4YjTVliRSaqNG6UsCq/x3f6R5/KBMacp4f0nZuXTOfvNgiFHju/m1paGf8JwylAkKummhneSOoZAbQ16dQhDu3ejZydbj5nRkTC/1VT87SFf+S+k66J8ycfIs2nkwlIvHWo+TbD36fBcTNq69BtAvluRRIH77zXg60zBK5KmmtKUbeayHVZngjZt/u3ezrRGuLu9TUCYtWMY0VVKyYUX36MykWY","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGFOUEXPF/20230518/eu-north-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=e643e2bb5d737954951f34ff67c4a11e00d022b402579f85ff9d99a5f70cbc53"}' }
  let(:regional_headers_signed_for_another_region) { '{"host":"sts.us-west-1.amazonaws.com","x-amz-date":"20230518T160804Z","x-amz-security-token":"IQoJb3JpZ2luX2VjEDgaDGV1LWNlbnRyYWwtMSJIMEYCIQDQLBDLt5kNEEj40A2gX/kurzw9AAwYKnJIjQSrXGynmQIhAINJPoMDfHiSe6Bjzuwc9lwbe/iUPkVUUClFbUicPhNtKrwFCGEQAxoMMTg4OTQ1NzY5MDA4IgyYkP5L6wWxumObWPQqmQXd1mkF8hU1CCkhdJdc73vLVnGFvGbqru9SpzDIkbo0/syIZR7pjEoPTw/sUxFa/jYgcRrDh9bUmTBT7zU2/HDJRrwZfNgu9PPEtRGkIUOYri8muc0X8yLnHlk/5jvpwU5RY2uUoTZt+pvgm8jOHi/lkrtPx8uiQeEOeBkKe/DA2tFfHeVrC9OPkWQkjm0k9nsDggpwy9jf+RbzeSRb6Tyg4WWplDKW+a7VhBpBs1cNGGx9um590gpgpxaC93CIAtxI+iOxreH+xofhrJAPirms1yR4f5GD+glhr/mpCdclX0Eehvb+nxosnYKMh8XvlKR1GzP/PtqGCCRMpCByPmiXtotOMEQv96QGGs0/A8vdiktjJuGbjSQxKvw1UNG5Cxrb7DRqexPoILxoZAICSiFDK2vPPl2ePTWrk3MFxBKj+UK2VihhE1fpnZ7UXrVmQAUzNtDTdaaTcWy2ZTf4oAcRkUsYUl1BOIQYEcI0LmpCkqHb51ANbPO9bFxLAGTUuV9AMSRcrEojiFlxl+yiK5lPygJzrbRQBhnh3srxoHjfN5KvgVf0PqS3HUWIX/eknhBTJbhPO9d7me1/rTudqFd1dLEEiTJbN6KGF0vZvAgnahcoA4YSxLhG/EkNdOKbS/lJOUeysN/l/3L19RuWX9gd2Pc2FD7KWM6mzNAFIi8OAIChTnhZO7a6lcYZb+5uY+5N3Oh2Qthx7cc5k0DGQXX2FGYQgQKY9MWQo6s3Z2DwfNDddgYEM2clnnNPP+lNU7evdCsDb4/QPyDv+l14Tmdz2adhcsi4hkX9YGaCko6S6tdPI1fURyTkCKfUJ643ZNXyqmx4vRPupO2ukJArh7piCas8+B4FsScjD1sD3dH9aVwa2sI1tVed9zCclpmjBjqwATqNRvOZinA+mqThE4YjTVliRSaqNG6UsCq/x3f6R5/KBMacp4f0nZuXTOfvNgiFHju/m1paGf8JwylAkKummhneSOoZAbQ16dQhDu3ejZydbj5nRkTC/1VT87SFf+S+k66J8ycfIs2nkwlIvHWo+TbD36fBcTNq69BtAvluRRIH77zXg60zBK5KmmtKUbeayHVZngjZt/u3ezrRGuLu9TUCYtWMY0VVKyYUX36MykWY","x-amz-content-sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","authorization":"AWS4-HMAC-SHA256 Credential=ASIASX7QLUIYGFOUEXPF/20230518/eu-north-1/sts/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=bfaefe50abefa68b0081af52687885a7391006f2c8b0d80b6c20beb7da808d56"}' }

  describe '.valid?' do
    context 'headers are valid' do
      context 'when using the global STS endpoint' do
        context 'with request signed by `us-east-1`' do
          let(:payload) do
            double('AuthenticationParameters', credentials: valid_global_headers, username: conjur_role)
          end
          it 'succeeds', vcr: 'authenticators/authn-iam/valid-global-headers' do
            expect(authenticator.valid?(payload)).to be(true)
          end
        end
        context 'with request signed for a non `us-east-1` region' do
          let(:payload) do
            double('AuthenticationParameters', credentials: global_non_global_signer, username: conjur_role)
          end
          it 'fails', vcr: 'authenticators/authn-iam/global-sts-non-global-signer' do
            expect { authenticator.valid?(payload) }
              .to raise_error(
                Errors::Authentication::AuthnIam::InvalidAWSHeaders,
                'CONJ00018E Invalid or expired AWS headers: Credential should be scoped to a valid region.'
              )
          end
        end
      end
      context 'when using the regional STS endpoint' do
        context 'when regional endpoint request was signed for that region' do
          let(:payload) do
            double('AuthenticationParameters', credentials: valid_regional_headers, username: conjur_role)
          end
          it 'succeeds', vcr: 'authenticators/authn-iam/valid-regional-headers' do
            expect(authenticator.valid?(payload)).to be(true)
          end
        end
        context 'when regional endpoint request was signed for another region' do
          let(:payload) do
            double('AuthenticationParameters', credentials: regional_headers_signed_for_another_region, username: conjur_role)
          end
          it 'fails', vcr: 'authenticators/authn-iam/regional-headers-signed-for-another-region' do
            expect { authenticator.valid?(payload) }
              .to raise_error(
                Errors::Authentication::AuthnIam::InvalidAWSHeaders,
                'CONJ00018E Invalid or expired AWS headers: Credential should be scoped to a valid region.'
              )
          end
        end
      end
    end
    context 'when headers are invalid' do
      context 'when headers have expired' do
        let(:payload) do
          double('AuthenticationParameters', credentials: expired_headers, username: conjur_role)
        end
        it 'fails with exception', vcr: 'authenticators/authn-iam/expired-headers' do
          expect { authenticator.valid?(payload) }
            .to raise_error(
              Errors::Authentication::AuthnIam::InvalidAWSHeaders,
              'CONJ00018E Invalid or expired AWS headers: Signature expired: 20230518T152442Z is now earlier than 20230518T153438Z (20230518T154938Z - 15 min.)'
            )
        end
      end
      context 'for the signing request' do
        context 'when the verb is not GET' do
          let(:payload) do
            double('AuthenticationParameters', credentials: different_signing_request_verb, username: conjur_role)
          end
          it 'fails with exception', vcr: 'authenticators/authn-iam/invalid-signing-request-verb' do
            expect { authenticator.valid?(payload) }
              .to raise_error(
                Errors::Authentication::AuthnIam::InvalidAWSHeaders,
                'CONJ00018E Invalid or expired AWS headers: The request signature we calculated does not match the signature you provided. Check your AWS Secret Access Key and signing method. Consult the service documentation for details.'
              )
          end
        end
        context 'when the signed URI is different' do
          let(:payload) do
            double('AuthenticationParameters', credentials: different_signing_request_uri, username: conjur_role)
          end
          it 'fails', vcr: 'authenticators/authn-iam/different-signing-request-url' do
            expect { authenticator.valid?(payload) }
              .to raise_error(
                Errors::Authentication::AuthnIam::InvalidAWSHeaders,
                'CONJ00018E Invalid or expired AWS headers: The request signature we calculated does not match the signature you provided. Check your AWS Secret Access Key and signing method. Consult the service documentation for details.'
              )
          end
        end
      end
    end
    context 'when an http exception occurs' do
      let(:authenticator) do
        Authentication::AuthnIam::Authenticator.new(
          env: [],
          client: class_double(Net::HTTP).tap do |double|
            allow(double).to receive(:get_response).and_raise(Timeout::Error)
          end
        )
      end
      let(:payload) do
        double('AuthenticationParameters', credentials: valid_global_headers, username: conjur_role)
      end
      it 'fails' do
        expect { authenticator.valid?(payload) }
          .to raise_error(
            Errors::Authentication::AuthnIam::VerificationError,
            'CONJ00063E Verification of IAM identity failed with exception: Timeout::Error'
          )
      end
    end
  end
  context 'for different roles' do
    context 'when login is a User' do
      let(:payload) do
        double('AuthenticationParameters', username: 'foo/bar/baz/188945769008/conjur-role', credentials: valid_global_headers)
      end
      it 'succeeds', vcr: 'authenticators/authn-iam/valid-global-headers' do
        expect(authenticator.valid?(payload)).to be(true)
      end
      context 'when login is in the root policy' do
        let(:payload) do
          double('AuthenticationParameters', username: '188945769008/conjur-role', credentials: valid_global_headers)
        end
        it 'fails', vcr: 'authenticators/authn-iam/valid-global-headers' do
          expect(authenticator.valid?(payload)).to be(false)
        end
      end
    end
    context 'when login is a host' do
      context 'when role has multiple policy nestings' do
        let(:payload) do
          double('AuthenticationParameters', username: 'host/foo/bar/baz/188945769008/conjur-role', credentials: valid_global_headers)
        end
        it 'succeeds', vcr: 'authenticators/authn-iam/valid-global-headers' do
          expect(authenticator.valid?(payload)).to be(true)
        end
      end
      context 'when account-id is missing from username' do
        let(:payload) do
          double('AuthenticationParameters', username: 'host/foo/bar/baz/conjur-role', credentials: valid_global_headers)
        end
        it 'fails', vcr: 'authenticators/authn-iam/valid-global-headers' do
          expect(authenticator.valid?(payload)).to be(false)
        end
      end
      context 'when login does not include an AWS resource id' do
        let(:payload) do
          double('AuthenticationParameters', username: 'host/foo/188945769008', credentials: valid_global_headers)
        end
        it 'fails', vcr: 'authenticators/authn-iam/valid-global-headers' do
          expect(authenticator.valid?(payload)).to be(false)
        end
      end
      context 'when login is in the root policy' do
        let(:payload) do
          double('AuthenticationParameters', username: 'host/188945769008/conjur-role', credentials: valid_global_headers)
        end
        it 'succeeds', vcr: 'authenticators/authn-iam/valid-global-headers' do
          expect(authenticator.valid?(payload)).to be(true)
        end
      end
    end
  end
end
