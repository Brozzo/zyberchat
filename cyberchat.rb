require 'rubygems'
require 'data_mapper'
require 'dm-postgres-adapter'
require './badwords.rb'
require 'sass'
DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{File.dirname(File.expand_path(__FILE__))}/cyberchat.db")

class User
	include DataMapper::Resource

	property :id,    Serial
	property :name,  String, :default => 'anonymous'
	property :admin, Boolean,  :default => false
	property :logged_in, Boolean, :default => false
end

DataMapper.finalize

class CyberChat < Sinatra::Application

	set :password, '1337'
	set :admin_password, 'gosebrozz1'
	$messages = []
	$color = ['#00FF00', '#000000']

	def initialize
		@user = User.create
	end

    configure :development do  
        DataMapper.auto_upgrade!  
    end
  
	get ('/style.css') {sass :style}
	get ('/error') {haml :error}
	get ('/') {haml :startpage}
	
	get '/chat' do
		redirect '/' unless @user.logged_in
		haml :chat
	end
	
	get '/fetch_messages' do
		$messages.reverse.map {|m|"<p><font color=\"#{$color[0]}\">#{m}</font><br></p>"}.join+"<style type=\"text/css\">body{background-color:#{$color[1]}}</style>"
	end
	
	post '/login' do
		if (params[:username].downcase =~ @@badnames or params[:username].length < 1)
		elsif params[:password] == settings.admin_password
			@user.logged_in = true
			@user.admin = true
			redirect '/chat'
		elsif params[:password] == settings.password
			@user.logged_in = true
			redirect '/chat'
		end

		redirect '/error'
	end
	
	get '/logout' do
		@user.logged_in = false
		@user.admin = false
		redirect '/'
	end
	
	post '/messages' do
		
		str = params[:message]
		s = str.downcase.split
		if str.length > 0
			print = true
		else
			print = false
		end
		
		#admin commands
		if @user.admin
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
			elsif s[0] == '/bgcolor'
				$color[1] = s[1]
				print = false
			end
		end
		
		str.gsub!(@@badwords, '*')
		hour = Time.now.localtime('+02:00').hour
		minute = Time.now.localtime('+02:00').min
		
		(0..9) === minute ? time = "#{hour}:0#{minute}" : time = "#{hour}:#{minute}"
		
		str = "#{session[:name]} - #{time} said: #{str}".split(//)
		t = str.length/60
		t += 1 if str.length%60 > 0
		t.times{|x| str.insert(60*x, '<br>') }
		str = str.join
		$messages << str if print
		
		n = 0
		$messages.each {n += 1}
		$messages.delete_at(0) if n > 40

	end
end
