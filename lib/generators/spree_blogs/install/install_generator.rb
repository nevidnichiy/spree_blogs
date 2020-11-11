module SpreeBlogs
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false

      def add_migrations
        run 'bundle exec rails acts_as_taggable_on_engine:install:migrations'

        if ActiveRecord::Base.connection.adapter_name == 'MySQL'
          rake acts_as_taggable_on_engine:tag_names:collate_bin
        end

        run 'bundle exec rails railties:install:migrations FROM=spree_blogs'
      end

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/frontend/all.js', "//= require spree/frontend/spree_blogs\n"
        append_file 'vendor/assets/javascripts/spree/backend/all.js', "//= require spree/backend/spree_blogs\n"
      end

      def add_stylesheets
        inject_into_file 'vendor/assets/stylesheets/spree/frontend/all.css', " *= require spree/frontend/spree_blogs\n", :before => /\*\//, :verbose => true
        inject_into_file 'vendor/assets/stylesheets/spree/backend/all.css', " *= require spree/backend/spree_blogs\n", :before => /\*\//, :verbose => true
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
        if run_migrations
          run 'bundle exec rails db:migrate'
        else
          puts 'Skipping rails db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
