require 'commands/base'

Dir["#{File.dirname(__FILE__)}/commands/*"].each { |c| require c }

module ExtJS::XTheme
	module Command
		class InvalidCommand < RuntimeError; end
		class CommandFailed  < RuntimeError; end
    class InvalidConfig < RuntimeError; end
    class ConfigNotFound < RuntimeError; end
    
		class << self
			def run(command, args, retries=0)
				begin
					run_internal(command, args.dup)
				rescue InvalidCommand
					error "Unknown command. Run 'xtheme help' for usage information."
				rescue CommandFailed => e
					error e.message
				rescue InvalidConfig => e
				  error e.message
				rescue ConfigNotFound => e
				  error e.message
				rescue Interrupt => e
					error "\n[canceled]"
				end
			end

			def run_internal(command, args, heroku=nil)
			  config = load_config
			  
				klass, method = parse(command)
				
				unless config || method == "init"
				  raise ConfigNotFound.new("Could not locate config file .xthemeconfig.\nAre you in your application root?  Have you run xtheme init?")
				end
				unless File.exists?(config[:ext_dir])
				  raise InvalidConfig.new("Could not locate ext_dir #{config[:ext_dir]}.\nAre you in your application root?")
				end
				unless File.exists?(config[:theme_dir])
				  raise InvalidConig.new("Could not locate theme_dir #{config[:theme_dir]}.\nAre you in your application root?")
				end
				
				runner = klass.new(args, config)
				raise InvalidCommand unless runner.respond_to?(method)
				runner.send(method)
			end

			def error(msg)
				STDERR.puts(msg)
				exit 1
			end

			def parse(command)
				parts = command.split(':')
				case parts.size
					when 1
						begin
							return eval("ExtJS::XTheme::Command::#{command.capitalize}"), :index
						rescue NameError, NoMethodError
						  return ExtJS::XTheme::Command::Theme, command
						end
					when 2
						begin
							return ExtJS::XTheme::Command.const_get(parts[0].capitalize), parts[1]
						rescue NameError
							raise InvalidCommand
						end
					else
						raise InvalidCommand
				end
			end
			
			def load_config
  	    File.exists?('.xthemeconfig') ? YAML::load(File.open('.xthemeconfig')) : nil
  	  end
		end
	end
end
