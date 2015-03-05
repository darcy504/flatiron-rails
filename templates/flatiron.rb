# Prevent automatic run of bundle install
def run_bundle ; end

# Helper method to write to secrets.yml
def add_secret_for(options)
  key = "#{options.first[0].to_s}"
  value = options.first[1]
  env = options[:env].to_s

  File.open("config/secrets.yml", "r+") do |f|
    out = ""
    f.each do |line|
      if line =~ /#{env}:/
        out << "#{line}"
        out << "  #{key}: #{value}\n"
      else
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

# Helper method to remove lines from a file
def remove_line_from_file(file, line_to_match)
  File.open(file, "r+") do |f|
    out = ""
    f.each do |line|
      unless line =~ /#{line_to_match}/i
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

# Helper method to remove part of a line in a file
def remove_part_of_line_from_file(file, line_to_remove)
  File.open(file, "r+") do |f|
    out = ""
    f.each do |line|
      if line =~ /#{line_to_remove}/
        out << "#{line.gsub("#{line_to_remove}", '')}"
      else
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

# Helper method to add a line to a file
def add_line_to_file(file, line_to_add, line_to_add_after)
  File.open(file, "r+") do |f|
    out = ""
    f.each do |line|
      if line =~ /#{line_to_add_after}/
        out << line + line_to_add
      else
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

# Helper method to add a line to a file by number
def add_line_by_number(file, line_to_add, line_number_under_which_to_add)
  File.open(file, "r+") do |f|
    out = ""
    f.each_with_index do |line, i|
      if line_number_under_which_to_add == i + 1
        out << line + line_to_add
      else
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end  
end

# Get formatted app name
def formatted_app_name
  app_name.split(/_|-/).map(&:capitalize).join(' ')
end

# Remove sqlite3 from default gem group and set Ruby version to 2.2.0
remove_line_from_file("Gemfile", "sqlite3")
file '.ruby-version', <<-RVM.strip_heredoc.chomp
  2.2.0
RVM

# Setup gem groups
gem_group :test, :development do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'database_cleaner'
  gem 'sqlite3'
  gem 'pry'
  gem 'guard-rspec', require: false
  gem 'thin'
end

gem_group :production do
  gem 'pg'
  gem 'google-analytics-rails'
  gem 'rails_12factor'
end

# Add bootstrap gem
gem 'bootstrap-sass', '~> 3.1.1'

# Delete README.rdoc
run 'rm README.rdoc'

# Add template data to README.md
file 'README.md', <<-README.strip_heredoc.chomp
  # #{formatted_app_name}

  ## Description

  Add a short description of your app.

  ## Screenshots

  Add some spiffy screenshots of your app here.

  ## Background

  Why did you want to make this app? What was your development process
  like?

  ## Features

  Bullet point some of the key features of your app here.

  ## Usage

  How do users use your app?

  ## Development/Contribution

  Explain how people can contribute to your app. How should they write tests?
  Any things in particular you'd like to see in pull requests?

  ## Future

  What features are you currently working on? Only mention things that you
  actually are implementing. No pie-in-the-sky-never-gonna-happen stuff.

  ## Author

  Link to your blog, twitter, etc!

  ## License

  #{formatted_app_name} is MIT Licensed. See LICENSE for details.
README

# Add LICENSE
file 'LICENSE', <<-MIT.strip_heredoc.chomp
  The MIT License (MIT)

  Copyright (c) [year] [fullname]

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
MIT

# Set Rails version to 4.2.0
File.open("Gemfile", "r+") do |f|
  out = ""
  f.each do |line|
    if line =~ /gem 'rails'/
      out << "#{line.gsub(/, '(.*)'/, ', \'4.2.0\'')}"
    else
      out << line
    end
  end
  f.pos = 0
  f.print out.chomp
  f.truncate(f.pos)
end

# Fix incorrect version of sass-rails
File.open("Gemfile", "r+") do |f|
  out = ""
  f.each do |line|
    if line =~ /gem 'sass-rails'/
      out << "#{line.gsub(/'~> 4.0.3'/, '\'4.0.2\'')}"
    else
      out << line
    end
  end
  f.pos = 0
  f.print out.chomp
  f.truncate(f.pos)
end

# Disable Turbolinks
remove_line_from_file("Gemfile", "turbolinks")
remove_line_from_file("app/assets/javascripts/application.js", "turbolinks")
remove_part_of_line_from_file("app/views/layouts/application.html.erb", ", 'data-turbolinks-track' => true")

# Optionally set up Devise
devise = false

if yes?("Use Devise? [y/N]")
  devise = true
  gem 'devise'
  environment 'config.action_mailer.default_url_options = { host: Rails.application.secrets.host }', env: 'production'
  add_secret_for(:host => 'YOUR PRODUCTION HOST URL/IP HERE', :env => 'production')
end

# Optionally set up Airbrake
airbrake = false
airbrake_api_key = ""

if yes?("Install Airbrake for error tracking? [y/N]")
  gem 'airbrake'

  if yes?("Do you already have an api key? (If not, set one up at https://airbrake.io/account/new/Free) [y/N]")
    airbrake_api_key = ask("What is it? (Don't worry, you can always set this up later.)")
    airbrake = true
  end
end

# Bundle
system("bundle")

# Install Devise
if devise
  run('rails generate devise:install')
  if yes?("Setup user model for Devise? [y/N]")
    model_name = ask("What do you want to call it (default=User)?").chomp.capitalize
    if model_name.size == 0
      model_name = "User"
    end

    run("rails generate devise #{model_name}")
    rake("db:migrate")
  end
end

# Install Airbrake
if airbrake
  if airbrake_api_key.length > 20
    run("rails generate airbrake --api-key #{airbrake_api_key}")
  end
end

# Generate RSpec files
generate(:"rspec:install")

# Fix .rspec file to remove excessive warnings/properly setup
remove_line_from_file('.rspec', '--warnings')
remove_line_from_file('.rspec', '--require spec_helper')
add_line_to_file('.rspec', "\n--format documentation", '--color')

# Edit spec/rails_helper.rb
File.open("spec/rails_helper.rb", "r+") do |f|
  out = ""
  f.each do |line|
    if line =~ /require 'rspec\/autorun'/
      # add SimpleCov
      out << line
      out << <<-CODE.strip_heredoc
      require 'simplecov'
      SimpleCov.start 'rails'
    CODE
    elsif line =~ /config\.fixture_path/
      # comment out fixtures
      out << "  ##{line[1..-1]}"
    elsif line =~ /config\.use_transactional_fixtures/
      # set transactional fixtures to false
      out << line.sub("true", "false")
    elsif line =~ /RSpec\.configure do/
      # add Database Cleaner
      out << line
      out << <<-CODE.gsub(/^ {6}/, '')
        config.include FactoryGirl::Syntax::Methods

        config.before(:suite) do
          DatabaseCleaner.clean_with(:truncation)
        end

        config.before(:each) do
          DatabaseCleaner.strategy = :transaction
          DatabaseCleaner.start
        end

        config.before(:each, :js => true) do
          DatabaseCleaner.strategy = :truncation
        end

        config.after(:each) do
          DatabaseCleaner.clean
        end
      CODE
    else
      out << line
    end
  end
  f.pos = 0
  f.print out.chomp
  f.truncate(f.pos)
end

# Make spec/features directory
run('mkdir -p spec/features')
run('touch spec/features/.keep')

# Create feature_helper.rb
file 'spec/feature_helper.rb', <<-CODE.strip_heredoc.chomp
  require 'rails_helper'
  require 'capybara/rails'
CODE

# Setup Guardfile
file 'Guardfile', %q(
  # guard 'rails' do
  #   watch('Gemfile.lock')
  #   watch(%r{^(config|lib)/.*})
  # end


  guard :rspec do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch('spec/rails_helper.rb')  { "spec" }

    # Rails example
    watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
    watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
    watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
    watch('config/routes.rb')                           { "spec/routing" }
    watch('app/controllers/application_controller.rb')  { "spec/controllers" }

    # Capybara features specs
    watch(%r{^app/views/(.+)/.*\.(erb|haml|slim)$})     { |m| "spec/features/#{m[1]}_spec.rb" }

    # Turnip features and steps
    watch(%r{^spec/acceptance/(.+)\.feature$})
    watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
  end
).strip.gsub(/^ {2}/, '')

# Set up Google Analytics
environment 'GA.tracker = Rails.application.secrets.google_analytics_code', env: 'production'
add_line_to_file("app/views/layouts/application.html.erb", "  <%= analytics_init if Rails.env.production? %>\n", "<%= csrf_meta_tags %>")
add_secret_for(google_analytics_code: 'YOUR CODE HERE', env: :production)

#Set up sprockets_better_errors
environment 'config.assets.raise_production_errors = true', env: 'development'

# Turn on precompile assets in production
File.open("config/environments/production.rb", "r+") do |f|
  out = ""
  f.each do |line|
    if line =~ /config.assets.compile = false/
      out << "  config.assets.compile = true\n"
    else
      out << line
    end
  end
  f.pos = 0
  f.print out.chomp
  f.truncate(f.pos)
end

# Set up Bootstrap
inside('app/assets/stylesheets') do
  run "mv application.css application.css.scss"
end

# Asset pipeline vendor
add_line_by_number("app/assets/stylesheets/application.css.scss", " *= require_tree ../../../vendor/assets/stylesheets/.\n", 12)
add_line_by_number("app/assets/javascripts/application.js", "//= require_tree ../../../vendor/assets/javascripts/.\n", 14)

depend_on_lines = [
  " //= depend_on_asset \"bootstrap/glyphicons-halflings-regular.svg\"\n",
  " //= depend_on_asset \"bootstrap/glyphicons-halflings-regular.ttf\"\n",
  " //= depend_on_asset \"bootstrap/glyphicons-halflings-regular.woff\"\n",
  " //= depend_on_asset \"bootstrap/glyphicons-halflings-regular.eot\"\n"
]

depend_on_lines.each do |line|
  add_line_to_file("app/assets/stylesheets/application.css.scss", line, /\*= require_self/)
end

add_line_to_file("app/assets/stylesheets/application.css.scss", "\n@import \"bootstrap\";", /\*\//)

File.open("app/assets/stylesheets/application.css.scss", "a") do |f|
  f.write <<-CSS.strip_heredoc.chomp
    
    /* Some Style from the Bootstrap Default Theme */
    body {
      padding-top: 70px;
      padding-bottom: 30px;
    }

    .theme-dropdown .dropdown-menu {
      position: static;
      display: block;
      margin-bottom: 20px;
    }

    .theme-showcase > p > .btn {
      margin: 5px 0;
    }
  CSS
end

File.open("app/assets/javascripts/application.js", "r+") do |f|
  out = ""
  jquery_count = 0
  f.each do |line|
    if line =~ /\/\/= require jquery/
      jquery_count += 1
      if jquery_count == 1
        out << "//= require jquery\n//= require jquery_ujs\n//= require bootstrap\n"
      end
    else
      out << line
    end
  end
  f.pos = 0
  f.print out.chomp
  f.truncate(f.pos)
end

# Add STACK description file
file 'STACK.md', <<-STACK.strip_heredoc.chomp
  This generator has set up the following stack:
    1. Testing
      * RSpec
      * Capybara
      * Database Cleaner
      * SimpleCov
      * Guard
    2. Frontend
      * Bootstrap
      * Disabled Turbolinks
      * Precompiled assets in production
    3. Gem groups set up for easy Heroku deployment
      * Postgres will work out of the box. No configuration necessary.
    4. Misc
      * Google Analytics

  TODO:
    1. Add the line `ruby '2.2.0'` to the top of your Gemfile
    2. An MIT License file has been created for you
      * Add your name and the year
    3. A README.md file has been started for you
      * Add relavent information and screenshots for your app
      * There is a basic template you can follow, but make it your own
    4. Google Analytics is set up to track your app
      * Set up an application on Google Analytics
      * You will need to add your analytics tracking code to `config/secrets.yml`
    5. Set up Airbrake (Optional)
      * If you entered your api key during project creation, you're all set!
      * Otherwise, visit [Airbrake](https://airbrake.io/account/new/Free) and set
      up a free account.
      * When it asks for "subdomain", it really means "username" (it's also a required
        field, even though it doesn't seem like it)
      * Generate your api key, then on your command line (in the project root), run:
        `rails g airbrake --api-key your_api_key_here

  Deploying to Heroku:
    1. `bin/setup [<app_name>]`
      * <app_name> is optional. It will, by default, attempt to create an
      app on Heroku using your Rails application name.
    2. `bin/deploy`

  Deploying to Ninefold:
    1. Create your app on Ninefold
    2. Add the given SSH key to your account on GitHub
    3. Choose the option for a single-server app
    4. Choose Ruby 2.1.0
    5. Change the name of the Environment Variable from SECRET_TOKEN to SECRET_KEY_BASE
    6. Click deploy (it will probably fail)
    7. Copy the relevant database information from the Database tab
    8. Paste that info in your `config/secrets.yml` file
    9. Push your changes
    10. Re-deploy on Ninefold
STACK

# Helper methods for Ninefold setup
def setup_database_yml_for_ninefold
  File.open("config/database.yml", "r+") do |f|
    out = ""
    f.each do |line|
      if line =~ /url:/
        out << <<-DB.gsub(/^ {8}/, '')
          adapter: postgresql
          encoding: utf8
          database: Rails.application.secrets.ninefold_db
          username: Rails.application.secrets.ninefold_user
          password: Rails.application.secrets.ninefold_pass
          host: localhost
          port: 5432
          pool: 10
        DB
      else
        out << line
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

def setup_secrets_yml_for_ninefold
  add_secret_for(ninefold_db: 'YOUR NINEFOLD DATABASE NAME HERE', env: :production)
  add_secret_for(ninefold_user: 'NINEFOLD DATABASE USERNAME HERE', env: :production)
  add_secret_for(ninefold_pass: 'NINEFOLD DATABASE PASSWORD HERE', env: :production)
end

def fix_new_database_yml_for_heroku
  File.open("config/database.yml", "r+") do |f|
    out = ""
    f.each do |line|
      if line =~ /production:/
        out << <<-DB.gsub(/^ {10}/, '')
          production:
            url: <%= ENV["DATABASE_URL"] %>
        DB
      else
        if !out.include?('production:')
          out << line
        end
      end
    end
    f.pos = 0
    f.print out.chomp
    f.truncate(f.pos)
  end
end

fix_new_database_yml_for_heroku

# Change setup for Ninefold
if yes?("Set up for Ninefold instead of Heroku? [y/N]")
  setup_database_yml_for_ninefold
  setup_secrets_yml_for_ninefold
  remove_line_from_file("Gemfile", "rails_12factor")
else
  file 'bin/setup', <<-SETUP.strip_heredoc.chomp
    #!/usr/bin/env ruby
    if ['-h', '--help'].include?(ARGV[0]) || ARGV[1]
      puts <<-HELP.gsub(/^ {6}/, '')
      Usage:
        bin/setup [<app_name>]
      HELP
    elsif ARGV[0]
      system("heroku create \#{ARGV[0]}")
    else
      system("heroku create \#{Dir.pwd.split('/').last}")
    end
  SETUP

  file 'bin/deploy', <<-DEPLOY.strip_heredoc.chomp
    #!/usr/bin/env ruby
    io = IO.popen("git remote -v")
    log = io.readlines

    if !log.any? {|line| line.match(/heroku/)}
      puts <<-ERROR.gsub(/^ {6}/, '')
      You must run `bin/setup` first!
      ERROR
    else
      system("git push heroku master && heroku run rake db:migrate && heroku open")
    end
  DEPLOY

  inside('bin') do
    run "chmod +x setup"
    run "chmod +x deploy"
  end

  begin
    heroku = IO.popen("heroku")
  rescue
    if yes?("It looks like you don't have Heroku installed yet. Install now? [y/N]")
      system("brew install heroku")
      system("heroku login")
    end
  end
end

# Initialize git repository and make initial commit
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }