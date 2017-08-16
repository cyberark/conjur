module Jekyll
  class EnvironmentVariablesGenerator < Generator
    def generate(site)
      site.config['env'] = ENV['JEKYLL_ENV'] || 'development'
      site.config['cpanel_url'] = ENV['CPANEL_URL'] || 'http://localhost:3000'
      # Add other environment variables to `site.config` here...
    end
  end
end
