require 'rubygems'
#require 'data_mapper'
#require 'dm-postgres-adapter'
require './badwords.rb'
require 'sass'

#DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{Dir.pwd}/cyberchat.db")

class CyberChat < Sinatra::Application
	
	set :password, '1337'
	set :admin_password, 'gosebrozz1'
	enable :sessions
	$messages = []
	$color = ['#00FF00', '#000000']
	
	get ('/style.css') {sass :style}
	get ('/error') {haml :error}
	get ('/') {haml :startpage}
	
	get '/chat' do
		redirect '/' unless session[:auth]
		haml :chat
	end
	
	get '/fetch_messages' do
		$messages.reverse.map {|m|"<p><font color=\"#{$color[0]}\">#{m}</font><br></p>"}.join+"<style type=\"text/css\">body{background-color:#{$color[1]}}</style>"
	end
	
	post '/login' do
		if params[:username].downcase =~ @@badnames
		elsif params[:password] == settings.admin_password
			session[:name] = params[:username]
			session[:auth] = :admin
			redirect '/chat'
		elsif params[:password] == settings.password
			session[:name] = params[:username]
			session[:auth] = :user
			redirect '/chat'
		end

		redirect '/error'
	end
	
	get '/logout' do
		session[:auth] = nil
		redirect '/'
	end
	
	post '/messages' do
		
		str = params[:message]
		s = str.downcase.split
		print = (params[:message].length > 0)
		
		#admin commands
		if session[:auth] == :admin
			if s[0] == '/delete'
				if s[1].to_i != 0
					n = s[1].to_i - 1
					$messages.delete_at(n)
					print = false
				end
			elsif s[0] == '/deleteall'
				$messages.clear
				print = false
			elsif s[0] == '/color'
				$color[0] = s[1]
				print = false
			elsif command[0] == '/bgcolor'
				$color[1] = s[1]
				print = false
			end
		end
		
		if s.any? {|word| word =~ @@badwords}
			str = ''
			s.each do |x|
				l = x.length
				if x =~ @@badwords
					l.times {str += '*'}
					str += ' '
				else
					str += "#{x} "
				end
			end
		end
		
		hour = Time.now.hour
		minute = Time.now.min
		
		(0..14) === hour ? hour += 9 : hour -= 15
		(0..9) === minute ? time = "#{hour}:0#{minute}" : time = "#{hour}:#{minute}"
		
		str = "#{session[:name]} - #{time} said: #{str}"
		$messages << message if print
		
		message_num = 0
		$messages.each {message_num += 1}
		$messages.delete_at(0) if message_num > 40

	end
end
