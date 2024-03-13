# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PolicyFactoryResourcesController, type: :request do
  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')

    # Simple Factories
    # rubocop:disable Layout/LineLength
    user_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHVzZXIgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgdXNlciIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSByZXNvdXJjZSB0eXBlIG9mIHRoZSBvd25lciBvZiB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sImlwX3JhbmdlIjp7ImRlc2NyaXB0aW9uIjoiTGltaXRzIHRoZSBuZXR3b3JrIHJhbmdlIHRoZSB1c2VyIGlzIGFsbG93ZWQgdG8gYXV0aGVudGljYXRlIGZyb20iLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    policy_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnbzhKU0JwWmlCa1pXWnBibVZrUHlodmQyNWxjbDl5YjJ4bEtTQW1KaUJrWldacGJtVmtQeWh2ZDI1bGNsOTBlWEJsS1NBdEpUNEtJQ0J2ZDI1bGNqb2dJVHdsUFNCdmQyNWxjbDkwZVhCbElDVStJRHdsUFNCdmQyNWxjbDl5YjJ4bElDVStDandsSUdWdVpDQXRKVDRLSUNCaGJtNXZkR0YwYVc5dWN6b0tQQ1VnWVc1dWIzUmhkR2x2Ym5NdVpXRmphQ0JrYnlCOGEyVjVMQ0IyWVd4MVpYd2dMU1UrQ2lBZ0lDQThKVDBnYTJWNUlDVStPaUE4SlQwZ2RtRnNkV1VnSlQ0S1BDVWdaVzVrSUMwbFBnbz0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiUG9saWN5IFRlbXBsYXRlIiwiZGVzY3JpcHRpb24iOiJDcmVhdGVzIGEgQ29uanVyIFBvbGljeSIsInR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7ImlkIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHBvbGljeSBpbnRvIiwidHlwZSI6InN0cmluZyJ9LCJvd25lcl9yb2xlIjp7ImRlc2NyaXB0aW9uIjoiVGhlIENvbmp1ciBSb2xlIHRoYXQgd2lsbCBvd24gdGhpcyBwb2xpY3kiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyBwb2xpY3kiLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
    # Complex Factory
    database_factory_without_breaker = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjFjbXdLSUNBZ0lDMGdJWFpoY21saFlteGxJSEJ2Y25RS0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhWelpYSnVZVzFsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J3WVhOemQyOXlaQW9nSUNBZ0xTQWhkbUZ5YVdGaWJHVWdjM05zTFdObGNuUnBabWxqWVhSbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RhMlY1Q2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J6YzJ3dFkyRXRZMlZ5ZEdsbWFXTmhkR1VLQ2lBZ0xTQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdMU0FoWjNKdmRYQWdZV1J0YVc1cGMzUnlZWFJ2Y25NS0lDQUtJQ0FqSUdOdmJuTjFiV1Z5Y3lCallXNGdjbVZoWkNCaGJtUWdaWGhsWTNWMFpRb2dJQzBnSVhCbGNtMXBkQW9nSUNBZ2NtVnpiM1Z5WTJVNklDcDJZWEpwWVdKc1pYTUtJQ0FnSUhCeWFYWnBiR1ZuWlhNNklGc2djbVZoWkN3Z1pYaGxZM1YwWlNCZENpQWdJQ0J5YjJ4bE9pQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdDaUFnSXlCaFpHMXBibWx6ZEhKaGRHOXljeUJqWVc0Z2RYQmtZWFJsSUNoaGJtUWdjbVZoWkNCaGJtUWdaWGhsWTNWMFpTd2dkbWxoSUhKdmJHVWdaM0poYm5RcENpQWdMU0FoY0dWeWJXbDBDaUFnSUNCeVpYTnZkWEpqWlRvZ0tuWmhjbWxoWW14bGN3b2dJQ0FnY0hKcGRtbHNaV2RsY3pvZ1d5QjFjR1JoZEdVZ1hRb2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHRmtiV2x1YVhOMGNtRjBiM0p6Q2lBZ0NpQWdJeUJoWkcxcGJtbHpkSEpoZEc5eWN5Qm9ZWE1nY205c1pTQmpiMjV6ZFcxbGNuTUtJQ0F0SUNGbmNtRnVkQW9nSUNBZ2JXVnRZbVZ5T2lBaFozSnZkWEFnWVdSdGFXNXBjM1J5WVhSdmNuTUtJQ0FnSUhKdmJHVTZJQ0ZuY205MWNDQmpiMjV6ZFcxbGNuTT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiRGF0YWJhc2UgQ29ubmVjdGlvbiBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQWxsIGluZm9ybWF0aW9uIGZvciBjb25uZWN0aW5nIHRvIGEgZGF0YWJhc2UiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6IlJlc291cmNlIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwidmFyaWFibGVzIjp7InR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7InVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInVybCIsInBvcnQiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl19fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiLCJ2YXJpYWJsZXMiXX19'
    database_factory = 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjFjbXdLSUNBZ0lDMGdJWFpoY21saFlteGxJSEJ2Y25RS0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhWelpYSnVZVzFsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J3WVhOemQyOXlaQW9nSUNBZ0xTQWhkbUZ5YVdGaWJHVWdjM05zTFdObGNuUnBabWxqWVhSbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RhMlY1Q2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J6YzJ3dFkyRXRZMlZ5ZEdsbWFXTmhkR1VLQ2lBZ0xTQWhaM0p2ZFhBS0lDQWdJR2xrT2lCamIyNXpkVzFsY25NS0lDQWdJR0Z1Ym05MFlYUnBiMjV6T2dvZ0lDQWdJQ0JrWlhOamNtbHdkR2x2YmpvZ0lsSnZiR1Z6SUhSb1lYUWdZMkZ1SUhObFpTQmhibVFnY21WMGNtbGxkbVVnWTNKbFpHVnVkR2xoYkhNdUlnb2dJQW9nSUMwZ0lXZHliM1Z3Q2lBZ0lDQnBaRG9nWVdSdGFXNXBjM1J5WVhSdmNuTUtJQ0FnSUdGdWJtOTBZWFJwYjI1ek9nb2dJQ0FnSUNCa1pYTmpjbWx3ZEdsdmJqb2dJbEp2YkdWeklIUm9ZWFFnWTJGdUlIVndaR0YwWlNCamNtVmtaVzUwYVdGc2N5NGlDaUFnQ2lBZ0xTQWhaM0p2ZFhBS0lDQWdJR2xrT2lCamFYSmpkV2wwTFdKeVpXRnJaWElLSUNBZ0lHRnVibTkwWVhScGIyNXpPZ29nSUNBZ0lDQmtaWE5qY21sd2RHbHZiam9nVUhKdmRtbGtaWE1nWVNCdFpXTm9ZVzVwYzIwZ1ptOXlJR0p5WldGcmFXNW5JR0ZqWTJWemN5QjBieUIwYUdseklHRjFkR2hsYm5ScFkyRjBiM0l1Q2lBZ0lDQWdJR1ZrYVhSaFlteGxPaUIwY25WbENpQWdDaUFnSXlCQmJHeHZkM01nSjJOdmJuTjFiV1Z5Y3ljZ1ozSnZkWEFnZEc4Z1ltVWdZM1YwSUdsdUlHTmhjMlVnYjJZZ1kyOXRjSEp2YldselpRb2dJQzBnSVdkeVlXNTBDaUFnSUNCdFpXMWlaWEk2SUNGbmNtOTFjQ0JqYjI1emRXMWxjbk1LSUNBZ0lISnZiR1U2SUNGbmNtOTFjQ0JqYVhKamRXbDBMV0p5WldGclpYSUtJQ0FLSUNBaklFRmtiV2x1YVhOMGNtRjBiM0p6SUdGc2MyOGdhR0Z6SUhSb1pTQmpiMjV6ZFcxbGNuTWdjbTlzWlFvZ0lDMGdJV2R5WVc1MENpQWdJQ0J0WlcxaVpYSTZJQ0ZuY205MWNDQmhaRzFwYm1semRISmhkRzl5Y3dvZ0lDQWdjbTlzWlRvZ0lXZHliM1Z3SUdOdmJuTjFiV1Z5Y3dvZ0lBb2dJQ01nUTI5dWMzVnRaWEp6SUNoMmFXRWdkR2hsSUdOcGNtTjFhWFF0WW5KbFlXdGxjaUJuY205MWNDa2dZMkZ1SUhKbFlXUWdZVzVrSUdWNFpXTjFkR1VLSUNBdElDRndaWEp0YVhRS0lDQWdJSEpsYzI5MWNtTmxPaUFxZG1GeWFXRmliR1Z6Q2lBZ0lDQndjbWwyYVd4bFoyVnpPaUJiSUhKbFlXUXNJR1Y0WldOMWRHVWdYUW9nSUNBZ2NtOXNaVG9nSVdkeWIzVndJR05wY21OMWFYUXRZbkpsWVd0bGNnb2dJQW9nSUNNZ1FXUnRhVzVwYzNSeVlYUnZjbk1nWTJGdUlIVndaR0YwWlNBb2RHaGxlU0JvWVhabElISmxZV1FnWVc1a0lHVjRaV04xZEdVZ2RtbGhJSFJvWlNCamIyNXpkVzFsY25NZ1ozSnZkWEFwQ2lBZ0xTQWhjR1Z5YldsMENpQWdJQ0J5WlhOdmRYSmpaVG9nS25aaGNtbGhZbXhsY3dvZ0lDQWdjSEpwZG1sc1pXZGxjem9nV3lCMWNHUmhkR1VnWFFvZ0lDQWdjbTlzWlRvZ0lXZHliM1Z3SUdGa2JXbHVhWE4wY21GMGIzSnoiLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiRGF0YWJhc2UgQ29ubmVjdGlvbiBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQWxsIGluZm9ybWF0aW9uIGZvciBjb25uZWN0aW5nIHRvIGEgZGF0YWJhc2UiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6IlJlc291cmNlIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwidmFyaWFibGVzIjp7InR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7InVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInVybCIsInBvcnQiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl19fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiLCJ2YXJpYWJsZXMiXX19'
    # rubocop:enable Layout/LineLength

    base_policy = <<~TEMPLATE
      - !policy
        id: conjur
        body:
        - !policy
          id: factories
          body:
          - !policy
            id: core
            annotations:
              description: "Create Conjur primatives and manage permissions"
            body:
            - !variable v1/user
            - !variable v1/policy

          - !policy
            id: connections
            annotations:
              description: "Create connections to external services"
            body:
            - !variable v1/database
            - !variable v2/database
    TEMPLATE

    post('/policies/rspec/policy/root', params: base_policy, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fuser', params: user_factory, env: request_env)
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fcore%2Fv1%2Fpolicy', params: policy_factory, env: request_env)
    # V1 includes the factory without circuit breakers
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv1%2Fdatabase', params: database_factory_without_breaker, env: request_env)
    # V2 includes the factory with the circuit breakers
    post('/secrets/rspec/variable/conjur%2Ffactories%2Fconnections%2Fv2%2Fdatabase', params: database_factory, env: request_env)
  end

  after(:all) do
    base_policy = <<~TEMPLATE
      - !delete
        record: !variable conjur/factories/core/v1/user
      - !delete
        record: !variable conjur/factories/core/v1/policy
      - !delete
        record: !policy conjur/factories/core
      - !delete
        record: !policy conjur/factories/connections
      - !delete
        record: !policy conjur/factories
      - !delete
        record: !policy conjur
    TEMPLATE

    patch('/policies/rspec/policy/root', params: base_policy, env: request_env)
  end

  def request_env(role: 'admin')
    {
      'HTTP_AUTHORIZATION' => access_token_for(role)
    }
  end

  describe 'POST #create' do
    context 'when policy factory is simple' do
      after(:each) do
        Role['rspec:user:rspec-user-1'].delete
      end
      it 'creates resources using policy factory' do
        user_params = {
          branch: 'root',
          id: 'rspec-user-1'
        }
        post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        response_json = JSON.parse(response.body)
        expect(response_json['created_roles'].key?('rspec:user:rspec-user-1')).to be(true)

        get('/roles/rspec/user/rspec-user-1', env: request_env)
        response_json = JSON.parse(response.body)
        expect(response_json['id']).to eq('rspec:user:rspec-user-1')
      end
    end
    context 'when policy factory is complex' do
      after(:each) do
        Resource['rspec:variable:test-database/url'].delete
        Resource['rspec:variable:test-database/port'].delete
        Resource['rspec:variable:test-database/username'].delete
        Resource['rspec:variable:test-database/password'].delete
        Role['rspec:policy:test-database'].delete
      end
      it 'creates resources using policy factory' do
        database_params = {
          id: 'test-database',
          branch: 'root',
          annotations: { foo: 'bar', baz: 'bang' },
          variables: {
            url: 'https://foo.bar.baz.com',
            port: '5432',
            username: 'foo-bar',
            password: 'bar-baz'
          }
        }
        post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        expect(response.status).to eq(201)
        expect(::Resource['rspec:variable:test-database/url']&.secret&.value).to eq('https://foo.bar.baz.com')
        expect(::Resource['rspec:variable:test-database/port']&.secret&.value).to eq('5432')
        expect(::Resource['rspec:variable:test-database/username']&.secret&.value).to eq('foo-bar')
        expect(::Resource['rspec:variable:test-database/password']&.secret&.value).to eq('bar-baz')
      end
    end
  end
  describe 'GET #show' do
    context 'when the requested resource was created from a "simple" factory' do
      context 'if the requested resource is a policy without variables' do
        before(:each) do
          policy_params = {
            branch: 'root',
            id: 'test-policy-1'
          }
          post('/factory-resources/rspec/core/policy', params: policy_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:policy:test-policy-1'].delete
        end
        it 'is unsuccessful' do
          get('/factory-resources/rspec/test-policy-1', env: request_env)

          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => { "message" => "This factory created resource: 'rspec:policy:test-policy-1' does not include any variables." }
          })
        end
      end
      context 'when the requested resource is not a policy' do
        before(:each) do
          user_params = {
            branch: 'root',
            id: 'rspec-user-1'
          }
          post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:user:rspec-user-1'].delete
        end

        it 'responds with an error' do
          get('/factory-resources/rspec/rspec-user-1', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => {
              "message" => "Policy 'rspec-user-1' was not found in account 'rspec'. Only policies with variables created from Factories can be retrieved using the Factory endpoint."
            }
          })
        end
      end
    end
    context 'when the requested resource was created from a "complex" factory' do
      context 'when the requested resource is present' do
        let(:database_factory_result) do
          {
            "annotations" => { "foo" => "bar", "baz" => "bang" },
            "id" => "test-database",
            "details" => { "classification" => "connections", "identifier" => "database", "version" => "v2" },
            "variables" => {
              "url" => {
                "value" => "https://foo.bar.baz.com",
                "description" => "Database URL"
              },
              "port" => {
                "value" => "5432",
                "description" => "Database Port"
              },
              "username" => {
                "value" => "foo-bar",
                "description" => "Database Username"
              },
              "password" => {
                "value" => "bar-baz",
                "description" => "Database Password"
              },
              "ssl-ca-certificate" => {
                "description" => "CA Root Certificate",
                "value" => nil
              }, "ssl-certificate" => {
                "description" => "Client SSL Certificate",
                "value" => nil
              }, "ssl-key" => {
                "description" => "Client SSL Key",
                "value" => nil
              }
            }
          }
        end
        context 'when the factory is created in the root namespace' do
          before(:each) do
            database_params = {
              id: 'test-database',
              branch: 'root',
              annotations: { foo: 'bar', baz: 'bang' },
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
          end
          after(:each) do
            Resource['rspec:variable:test-database/url'].delete
            Resource['rspec:variable:test-database/port'].delete
            Resource['rspec:variable:test-database/username'].delete
            Resource['rspec:variable:test-database/password'].delete
            Role['rspec:policy:test-database'].delete
          end

          it 'returns the factory resource' do
            get('/factory-resources/rspec/test-database', env: request_env)
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json).to eq(database_factory_result)
          end
        end
        context 'when the factory is created in an interior namespace' do
          before(:each) do
            post('/factory-resources/rspec/core/policy', params: { id: 'foo', branch: 'root' }.to_json, env: request_env)
            post('/factory-resources/rspec/core/policy', params: { id: 'bar', branch: 'foo' }.to_json, env: request_env)
            post('/factory-resources/rspec/core/policy', params: { id: 'baz', branch: 'foo/bar' }.to_json, env: request_env)

            database_params = {
              id: 'test-database',
              branch: 'foo/bar/baz',
              annotations: { foo: 'bar', baz: 'bang' },
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
          end
          after(:each) do
            Resource['rspec:variable:foo/bar/baz/test-database/url'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/port'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/username'].delete
            Resource['rspec:variable:foo/bar/baz/test-database/password'].delete
            Role['rspec:policy:foo/bar/baz/test-database'].delete
          end

          it 'returns the factory resource' do
            get('/factory-resources/rspec/foo%2Fbar%2Fbaz%2Ftest-database', env: request_env)
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json).to eq(
              database_factory_result.merge(
                "id" => "foo/bar/baz/test-database"
              )
            )
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/url']&.secret&.value).to eq('https://foo.bar.baz.com')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/port']&.secret&.value).to eq('5432')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/username']&.secret&.value).to eq('foo-bar')
            expect(::Resource['rspec:variable:foo/bar/baz/test-database/password']&.secret&.value).to eq('bar-baz')
          end
        end
      end
      context 'when the requested resource is not present' do
        it 'responds with an error' do
          get('/factory-resources/rspec/test-database', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(404)
          expect(response_json).to eq({
            "code" => 404,
            "error" => {
              "message" => "Policy 'test-database' was not found in account 'rspec'. Only policies with variables created from Factories can be retrieved using the Factory endpoint."
            }
          })
        end
      end
    end
  end
  describe 'GET #index' do
    context 'when no complex factory resources are available' do
      context 'when no resources have been created with simple factories' do
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
      context 'when simple factory resources have been created' do
        before(:each) do
          user_params = {
            branch: 'root',
            id: 'rspec-user-1'
          }
          post('/factory-resources/rspec/core/user', params: user_params.to_json, env: request_env)
        end
        after(:each) do
          Role['rspec:user:rspec-user-1'].delete
        end
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
      context 'when role does not have access to created resources' do
        before(:each) do
          database_params = {
            id: 'test-database',
            branch: 'root',
            annotations: { foo: 'bar', baz: 'bang' },
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
          post('/factory-resources/rspec/core/user', params: { branch: 'root', id: 'rspec-user-1' }.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-database/url'].delete
          Resource['rspec:variable:test-database/port'].delete
          Resource['rspec:variable:test-database/username'].delete
          Resource['rspec:variable:test-database/password'].delete
          Role['rspec:policy:test-database'].delete
          Role['rspec:user:rspec-user-1'].delete
        end
        it 'responds with an empty set' do
          get('/factory-resources/rspec', env: request_env(role: 'rspec-user-1'))
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([])
        end
      end
    end
    context 'when complex factory resources are available' do
      before(:each) do
        database_params = {
          id: 'test-database',
          branch: 'root',
          variables: {
            url: 'https://foo.bar.baz.com',
            port: '5432',
            username: 'foo-bar',
            password: 'bar-baz'
          }
        }
        post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
      end
      after(:each) do
        Resource['rspec:variable:test-database/url'].delete
        Resource['rspec:variable:test-database/port'].delete
        Resource['rspec:variable:test-database/username'].delete
        Resource['rspec:variable:test-database/password'].delete
        Role['rspec:policy:test-database'].delete
      end
      context 'when one resource has been created' do
        it 'responds with the created resource' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json).to eq([{
            'annotations' => {},
            'details' => {
              'classification' => 'connections',
              'identifier' => 'database',
              'version' => 'v2'
            },
            'id' => 'test-database',
            'variables' => {
              'password' => {
                'description' => 'Database Password',
                'value' => 'bar-baz'
              },
              'port' => {
                'description' => 'Database Port',
                'value' => '5432'
              },
              'ssl-ca-certificate' => {
                'description' => 'CA Root Certificate',
                'value' => nil
              },
              'ssl-certificate' => {
                'description' => 'Client SSL Certificate',
                'value' => nil
              },
              'ssl-key' => {
                'description' => 'Client SSL Key',
                'value' => nil
              },
              'url' => {
                'description' => 'Database URL',
                'value' => 'https://foo.bar.baz.com'
              },
              'username' => {
                'description' => 'Database Username',
                'value' => 'foo-bar'
              }
            }
          }])
        end
      end
      context 'when multiple resources have been created' do
        before(:each) do
          database_params = {
            id: 'test-database-2',
            branch: 'root',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-database-2/url'].delete
          Resource['rspec:variable:test-database-2/port'].delete
          Resource['rspec:variable:test-database-2/username'].delete
          Resource['rspec:variable:test-database-2/password'].delete
          Role['rspec:policy:test-database-2'].delete
        end
        it 'responds with the created resources' do
          get('/factory-resources/rspec', env: request_env)
          response_json = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(response_json.count).to eq(2)
          expect(response_json.first['id']).to eq('test-database')
          expect(response_json.last['id']).to eq('test-database-2')
        end
        context 'when a role does not have permission to view all resources' do
          before(:each) do
            # grant rspec-user-1 the role of consumer on test-database-2
            post('/factory-resources/rspec/core/user', params: { branch: 'root', id: 'rspec-user-1' }.to_json, env: request_env)
            grant_policy = <<~TEMPLATE
              - !grant
                member: !user rspec-user-1
                role: !group test-database-2/consumers
            TEMPLATE
            post('/policies/rspec/policy/root', params: grant_policy, env: request_env)
          end
          after(:each) do
            Role['rspec:user:rspec-user-1'].delete
          end
          it 'responds with an empty set' do
            get('/factory-resources/rspec', env: request_env(role: 'rspec-user-1'))
            response_json = JSON.parse(response.body)

            expect(response.status).to eq(200)
            expect(response_json.count).to eq(1)
            expect(response_json.first['id']).to eq('test-database-2')
          end
        end
      end
    end
  end
  describe 'POST #enable' do
    context 'when resource has been created from a factory' do
      context 'when the created resource is in the root policy' do
        after(:each) do
          Resource['rspec:variable:test-database/url']&.delete
          Resource['rspec:variable:test-database/port']&.delete
          Resource['rspec:variable:test-database/username']&.delete
          Resource['rspec:variable:test-database/password']&.delete
          Role['rspec:policy:test-database']&.delete
        end
        context 'when a factory does not have circuit breakers' do
          it 'is returns an error' do
            database_params = {
              id: 'test-database',
              branch: 'root',
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
            post('/factory-resources/rspec/test-database/enable', env: request_env)

            expect(response.status).to eq(501)
            response_json = JSON.parse(response.body)
            expect(response_json['error']['message']).to eq("Factory generated policy 'test-database' does not include a circuit-breaker group.")
          end
        end
        context 'when factory has circuit breakers' do
          context 'when the resource is currently enabled' do
            context 'when we attempt to enable it again' do
              it 'is successful' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/enable', env: request_env)

                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(true)
              end
            end
          end
          context 'when the resource is currently disabled' do
            context 'when we attempt to enable it' do
              it 'restores access' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/disable', env: request_env)
                # verify disabled
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(false)

                # then enable
                post('/factory-resources/rspec/test-database/enable', env: request_env)
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(true)
              end
            end
          end
        end
      end
      context 'when the created resource is in an interior policy' do
        before(:each) do
          post(
            '/factory-resources/rspec/core/policy',
            params: { branch: 'root', id: 'test-policy-1' }.to_json,
            env: request_env
          )
          database_params = {
            id: 'test-database-2',
            branch: 'test-policy-1',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-policy-1/test-database-2/url'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/port'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/username'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/password'].delete
          Role['rspec:group:test-policy-1/test-database-2/consumers'].delete
          Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].delete
          Role['rspec:group:test-policy-1/test-database-2/administrators'].delete
          Role['rspec:policy:test-policy-1/test-database-2'].delete
          Role['rspec:policy:test-policy-1'].delete
        end
        context 'when the resource is currently disabled' do
          context 'when we attempt to enable it' do
            it 'restores access' do
              # Trip the circuit breaker
              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/disable', env: request_env)
              # Verify it is disabled
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
              ).to eq(false)

              # Enable
              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/enable', env: request_env)
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
              ).to eq(true)
            end
          end
        end
      end
    end
  end
  describe 'POST #disable' do
    context 'when a resource has been created from a factory' do
      context 'when the created resource is in the root policy' do
        after(:each) do
          Resource['rspec:variable:test-database/url']&.delete
          Resource['rspec:variable:test-database/port']&.delete
          Resource['rspec:variable:test-database/username']&.delete
          Resource['rspec:variable:test-database/password']&.delete
          Role['rspec:policy:test-database']&.delete
        end
        context 'when a factory does not have circuit breaker' do
          it 'returns an error' do
            database_params = {
              id: 'test-database',
              branch: 'root',
              variables: {
                url: 'https://foo.bar.baz.com',
                port: '5432',
                username: 'foo-bar',
                password: 'bar-baz'
              }
            }
            post('/factory-resources/rspec/connections/v1/database', params: database_params.to_json, env: request_env)
            post('/factory-resources/rspec/test-database/disable', env: request_env)

            expect(response.status).to eq(501)
            response_json = JSON.parse(response.body)
            expect(response_json['error']['message']).to eq("Factory generated policy 'test-database' does not include a circuit-breaker group.")
          end
        end
        context 'when factory has a circuit breaker' do
          context 'when the resource is currently disabled' do
            context 'when we attempt to disable it again' do
              it 'is successful' do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                post('/factory-resources/rspec/test-database/disable', env: request_env)

                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                ).to eq(false)
              end
            end
          end
          context 'when the resource is currently enabled' do
            context 'when we attempt to disable it' do
              before(:each) do
                database_params = {
                  id: 'test-database',
                  branch: 'root',
                  annotations: { foo: 'bar', baz: 'bang' },
                  variables: {
                    url: 'https://foo.bar.baz.com',
                    port: '5432',
                    username: 'foo-bar',
                    password: 'bar-baz'
                  }
                }
                post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
                # verify the breaker has not been tripped
                unless Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  post('/factory-resources/rspec/test-database/enable', env: request_env)
                  expect(response.status).to eq(200)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(true)
                end
              end
              context 'when the role has update permission on the policy' do
                it 'removes access' do
                  post('/factory-resources/rspec/test-database/disable', env: request_env)
                  # verify disabled
                  expect(response.status).to eq(200)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(false)
                end
              end
              context 'when the role does not have update permission on the policy' do
                before(:each) do
                  Role.find_or_create(role_id: 'rspec:user:alice')
                end
                after(:each) do
                  Role['rspec:user:alice'].delete
                end
                it 'responds with an error' do
                  post('/factory-resources/rspec/test-database/disable', env: request_env(role: 'alice'))
                  # verify circuit breaker is not disabled
                  expect(response.status).to eq(403)
                  expect(
                    Role['rspec:group:test-database/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
                  ).to eq(true)
                end
              end
            end
          end
        end
      end
      context 'when the created resource is in an interior policy' do
        before(:each) do
          post(
            '/factory-resources/rspec/core/policy',
            params: { branch: 'root', id: 'test-policy-1' }.to_json,
            env: request_env
          )
          database_params = {
            id: 'test-database-2',
            branch: 'test-policy-1',
            variables: {
              url: 'https://foo.bar.baz.com',
              port: '5432',
              username: 'foo-bar',
              password: 'bar-baz'
            }
          }
          post('/factory-resources/rspec/connections/database', params: database_params.to_json, env: request_env)
        end
        after(:each) do
          Resource['rspec:variable:test-policy-1/test-database-2/url'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/port'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/username'].delete
          Resource['rspec:variable:test-policy-1/test-database-2/password'].delete
          Role['rspec:group:test-policy-1/test-database-2/consumers'].delete
          Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].delete
          Role['rspec:group:test-policy-1/test-database-2/administrators'].delete
          Role['rspec:policy:test-policy-1/test-database-2'].delete
          Role['rspec:policy:test-policy-1'].delete
        end
        context 'when the resource is currently enabled' do
          context 'when we attempt to disable it' do
            it 'removes access' do
              # verify the breaker has not been tripped
              unless Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
                post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/enable', env: request_env)
                expect(response.status).to eq(200)
                expect(
                  Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-policy-1/test-database-2/consumers' }
                ).to eq(true)
              end

              post('/factory-resources/rspec/test-policy-1%2Ftest-database-2/disable', env: request_env)
              # verify disabled
              expect(response.status).to eq(200)
              expect(
                Role['rspec:group:test-policy-1/test-database-2/circuit-breaker'].memberships.any? { |member| member.member_id == 'rspec:group:test-database/consumers' }
              ).to eq(false)
            end
          end
        end
      end
    end
  end
end
