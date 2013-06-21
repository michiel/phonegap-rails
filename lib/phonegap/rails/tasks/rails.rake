
namespace :phonegap do
  namespace :rails do
    config_path = File.join(Rails.root, 'config', 'phonegap_rails.yml')
    if File.exist?(config_path)
      config_file = File.read(config_path)
      config = YAML.load(config_file)
      unless config.nil? or config === false
        unless config['phonegap_path'].nil?
          phonegap_path = config['phonegap_path']
          scripts_path = phonegap_path + '/lib/android/bin'
        end
        main_activity = Rails.application.class.to_s.split("::").first
        project_path = 'phonegap/android/' + main_activity
        unless config['android'].nil?
          package = config['android']["package"] unless config['android']["package"].nil?
        end
        @api_server = config['api_server'] unless config['api_server'].nil?
      end
    end
    
    namespace :android do
      
      desc 'Perform all tasks required to run the application as an Android project'
      task :initall => [:create,:export,:build,:emulate] do
      end
      
      desc 'create Phonegap project for android'
      task :create => :environment do
        if phonegap_path.blank?
          puts "You have to specify phonegap path at config/phonegap_rails.yml"
          abort
        end
        if package.blank?
          puts "You have to specify an android package at config/phonegap_rails.yml"
          abort
        end
        puts "Creating android project"     
        command = "#{scripts_path}/create #{project_path} #{package} #{main_activity}"
        puts "creating project: #{command}"
        puts `#{command}`
      end
      desc 'export application assets to android phonegap project'
      task :export => :environment do
        puts "Exporting android project"
        environment = Rails.application.assets
        ## Export js assets
        puts '* javascript assets'
        file = File.open("#{project_path}/assets/www/js/application.js", "w")
        file.write environment['application.js']
        file.close
        ## Export css assets
        puts '* css assets'
        file = File.open("#{project_path}/assets/www/css/application.css", "w")
        file.write environment['application.css']
        file.close
        ## Export images and fonts
        puts '* images and fonts'
        FileUtils.mkdir_p "#{project_path}/assets/www/assets"
        other_paths = Rails.configuration.assets.paths.select {|x| x =~ /\/fonts$|\/images$/}
        other_paths.each do |path|
          files = Dir.glob("#{path}/**/*.*")
          files.each do |file|
            FileUtils.cp file, "#{project_path}/assets/www/assets"
          end
        end
        ## Export public folder
        puts '* public folder'
        Dir.glob("public/**/*.*").each do |file|
          FileUtils.cp file, "#{project_path}/assets/www/" unless file =~ /public\/assets\//
        end
        puts '* index.html'
        @app_title = main_activity
        public_source = File.expand_path('../../../../public', __FILE__)
        file = File.open("#{project_path}/assets/www/index.html", "w")
        file.write ERB.new(File.read("#{public_source}/android_index.html.erb")).result
        file.close
        ## Fix relative paths and configure API server
        css_file_path = "#{project_path}/assets/www/css/application.css"
        css_file = File.read(css_file_path)
        new_css_file = css_file.gsub(/\/assets/, '../assets')
        file = File.open(css_file_path, "w")
        file.puts new_css_file
        file.close        
        js_file_path = "#{project_path}/assets/www/js/application.js"
        js_file = File.read(js_file_path)
        new_js_file = js_file.gsub(/src=\\"\//, 'src=\"')
        if @api_server.blank?
          puts "Warning: No API server is specified for this app"
        else
          if new_js_file =~ /href=\\"\//
            puts "Relative paths found. Making absolute to reference API: #{@api_server}"
            new_js_file.gsub!(/href=\\"\//, 'href=\"'+@api_server+'/')
          end
        end
        file = File.open(js_file_path, "w")
        file.puts new_js_file
        file.close
        
      end
      desc 'build android phonegap project'
      task :build => :environment do
        command = "#{project_path}/cordova/build"
        puts "Building project: #{command}"
        puts `#{command}`
      end
      desc 'Launch emulator for android phonegap project'
      task :emulate => :environment do
        command = "#{project_path}/cordova/run"
        puts "Launching emulator: #{command}"
        puts `#{command}`
      end
      desc 'Clean android phonegap project'
      task :clean => :environment do
        command = "#{project_path}/cordova/clean"
        puts "Cleaning project: #{command}"
        puts `#{command}`
      end
      desc 'Log'
      task :log => :environment do
        command = "#{project_path}/cordova/log"
        puts "Log: #{command}"
        puts `#{command}`
      end
      desc 'Check Android environment'
      task :check => :environment do

        # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
        # Cross-platform way of finding an executable in the $PATH.
        #
        #  which('ruby') #=> /usr/bin/ruby
        #
        #  Included here to prevent global pollution

        def which(cmd)
          exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
          ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
            exts.each { |ext|
              exe = File.join(path, "#{cmd}#{ext}")
              return exe if File.executable? exe
            }
          end
          return nil
        end

        puts 'Checking Android files'

        bins_not_found = []
        envs_not_found = []

        required_bins = ['ant', 'adb', 'android']
        required_envs = ['ANDROID_SKD_HOME']

        required_envs.each do |env|
          print "\tChecking for ENV '#{env}' .. "
          if ENV[env]
            puts "OK"
          else
            puts "NOT FOUND"
            envs_not_found.push env
          end
        end

        required_bins.each do |bin|
          print "\tChecking for executable '#{bin}' .. "
          if which(bin)
            puts "OK"
          else
            puts "NOT FOUND"
            bins_not_found.push bin
          end
        end

        if envs_not_found.size != 0
          puts "Environment variable(s) #{envs_not_found.to_s} missing. Android builds might fail."
        end

        if bins_not_found.size != 0
          puts "File(s) #{bins_not_found.to_s} missing from environment. Android builds will fail."
        end

      end
    end
    namespace :ios do
      desc 'export Phonegap project for ios'
      task :export  => :environment do
        # TODO: export project
        puts "Not implemented"
      end
    end
  end
end
