require 'date'
require 'time'

# Web interface / presentation

# Read in the file in lines
def readfile(filename)
	return IO.readlines(filename)
end

# TIMESTAMP [TAB] SENDER_FIRSTNAME [SPACE] SENDER_LASTNAME [SPACE] MESSAGE
# TIMESTAMP = 1:23 OR 12:34
def extract(line)

	line = line.chomp()
	
	# parse line
	#https://www.rubyguides.com/2015/06/ruby-regex/
	parse_line = line.match(FORMAT) { |m| LINE.new(*m.captures, "m") }
	
	# set correct message type
	if parse_line.msg == "[Photo]"
		parse_line.type = "p"
	elsif parse_line.msg == "[Sticker]"
		parse_line.type = "s"
	elsif parse_line.msg == "[Video]"
		parse_line.type = "v"
	end

	return parse_line
end

def find_datetime(ent)
	format = "%Y/%m/%d-%a %k:%M"
	# set date & time from parsed data
	date = ent.date.year+"/"+ent.date.month+"/"+ent.date.day+"-"+ent.date.weekday
	time = ent.LINE.time

	# Handle weird japanese clock issue (24 == 00), for correct parsing
	if time[0..1] == "24"
		time[0..1] = "00"
	end

	# Parse date and time to datetime object
	return DateTime.strptime(date+" "+time, format)
end

def add_sender_data(sender, datetime, ent, sender_message)
	# If sender doesn't exist, create the first entry in the senders array of messages, else append it.
	if sender_message[sender] == nil
		sender_message[sender] = [{date: datetime, msg:ent.LINE.msg, type: ent.LINE.type}]
	else
		sender_message[sender].push({date: datetime, msg:ent.LINE.msg, type: ent.LINE.type})
	end
end

def add_word_data(word, words)

	word = word.downcase
	# replace () with space
	word.gsub!(/[\(\)]/, ' ')

	# remove any special characters
	word.gsub!(/[^0-9A-Za-z ]/, '')

	#Handle spaces added as part of cleaning
	word = word.split
	# iterate over words
	for w in word
		# remove filler word. (the, this, that...etc)
		ignore_words = ["to","of","in","for","on","with","at","by","from","up","about","into","over","after","others","the","and","a","that","I","it","not","he","as","you","this","but","his","they","her","she","or","an","will","my","one","all","would","there","their", "i", "am", "ourselves", "hers", "between", "yourself", "but", "again", "there", "about", "once", "during", "out", "very", "having", "with", "they", "own", "an", "be", "some", "for", "do", "its", "yours", "such", "into", "of", "most", "itself", "other", "off", "is", "s", "am", "or", "who", "as", "from", "him", "each", "the", "themselves", "until", "below", "are", "we", "these", "your", "his", "through", "don", "nor", "me", "were", "her", "more", "himself", "this", "down", "should", "our", "their", "while", "above", "both", "up", "to", "ours", "had", "she", "all", "no", "when", "at", "any", "before", "them", "same", "and", "been", "have", "in", "will", "on", "does", "yourselves", "then", "that", "because", "what", "over", "why", "so", "can", "did", "not", "now", "under", "he", "you", "herself", "has", "just", "where", "too", "only", "myself", "which", "those", "i", "after", "few", "whom", "t", "being", "if", "theirs", "my", "against", "a", "by", "doing", "it", "how", "further", "was", "here", "than", "ok"]
		# if found, go to next word
		if ignore_words.include? w
			next
		end

		# if first time, set count to 1, else increment by one
		if words[w] == nil
			words[w] = 1
		else
			words[w] += 1
		end
	end
end

def extract_word_stats(words, result)
	
	# Unique words
	result[:uniq] = words.length
	
	# Sorted list of how many times each word is used
	sorted = words.each_with_object({}) { |(k,v),g| (g[v] ||= []) << k }
	
	# How many times is most used word used
	high = sorted.max_by{|k,v| k}[0]

	# Save results 
	result[:most_nr] = high
	result[:most] = sorted[high]
	result[:least] = sorted[1]
	result[:sorted] = sorted
end

def analyze_pr_sender(data)
	#Data
	# Name, [ent, ent]
	# ent = {datetime, msg, type}
	
	#Res
	# res[usr] = {msg_stats: {msg_nr, stamp_nr, photo_nr}, word_stats: {uniq, most, least}, reply_time}
	res = Hash.new()

	# Go through all messages per sender 
	data.each_key do |user|
		wordlist = {}
		res[user] = {msg_stats: {text_nr:0, stamp_nr:0, photo_nr:0, vid_nr:0, tot_nr:0}, word_stats: {uniq:0, most:[], most_nr:0, least:[], sorted:nil}, reply_time:nil}
		
		# Go through messages for current sender
		data[user].each do |msg_data|
			
			# Count messages
			res[user][:msg_stats][:tot_nr] += 1

			# Analyse message types sent
			if msg_data[:type] == "p"
				res[user][:msg_stats][:photo_nr] += 1
			elsif msg_data[:type] == "s"
				res[user][:msg_stats][:stamp_nr] += 1
			elsif msg_data[:type] == "v"
				res[user][:msg_stats][:vid_nr] += 1
			else
				res[user][:msg_stats][:text_nr] += 1
			end
			
			# word analysis per user
			if msg_data[:type] == "m"
				for word in msg_data[:msg].split
					add_word_data(word, wordlist)
				end
			end

		end

		# Get word stats for current user
		extract_word_stats(wordlist, res[user][:word_stats])
	end

	return res
end

def get_reply_time(reply_time, q_time)
	#find diff between q_time and reply_time in seconds
	diff = reply_time.to_time.to_i - q_time.to_time.to_i
	#puts diff
	return diff
end

def add_reply_time(object, reply_time)
	#find response time for first reply
	if object == nil
		return {time: reply_time, num: 1.0}
	end
	object[:time] = object[:time] + reply_time
	object[:num] += 1
	return object
end

def analyze_reply_time(object)
	# Return average
	return (object[:time] / object[:num])
end

def get_string_time(int_time)
	str = ""

	if int_time == -1
		return "No data !"
	end

	if ((int_time / (60*60*24)).round)>0
		str += "Day(s): " + ((int_time / (60*60*24)).round).to_s
	end
	str += " Time "
	
	str += "%02d" % ((int_time / (60*60)) % 24) + ":"
	str += "%02d" % ((int_time / (60))%60) + ":"
	str += "%02d" % (int_time%60)
	return str
end

def printout(words, stickers, images, videos, chat_txt, msg_amt, res, percent_dist, reply_time_res, wihtin_hr, questions_asked)
	tot_q = 0
	questions_asked.each_key do |asked|
		tot_q += questions_asked[asked]
	end
	puts "********************* Conversation stats *********************"
	puts "Total questions asked: ".ljust(30) + tot_q.to_s.rjust(5)
	puts "Total unique words sent: ".ljust(30) + words.length.to_s.rjust(5)
	puts "Total stickers sent: ".ljust(30) + stickers.to_s.rjust(5)
	puts "Total images sent: ".ljust(30) + images.to_s.rjust(5)
	puts "Total videos sent: ".ljust(30) + videos.to_s.rjust(5)
	puts "Total text messages sent: ".ljust(30) + chat_txt.to_s.rjust(5)
	puts "Total messages sent: ".ljust(30) + msg_amt.to_s.rjust(5)
	
	puts "\n********************* Stats pr. User *********************\n"
	#For each user
	res.each_key do |user|
		# Print User stats
		puts "\n--------------------- " + user + " ---------------------\n"
		puts user + " sent " + percent_dist[user].round.to_s + "\% of all messages (" + res[user][:msg_stats][:tot_nr].to_s + "/" + msg_amt.to_s + ")"
		puts "++++++++++++ Word stats ++++++++++++"
		puts "Questions asked".ljust(25) + questions_asked[user].to_s.rjust(10)
		puts "Unique words: ".ljust(25) + res[user][:word_stats][:uniq].to_s.rjust(10)
		puts "Most used words: ".ljust(25) + res[user][:word_stats][:most].first(10).join(", ").rjust(10)
		puts "Were used ".ljust(28) + res[user][:word_stats][:most_nr].to_s + " times"
		puts "Words used only once:"
		puts res[user][:word_stats][:least].first(10).join(", ")
		puts "\n++++++++++++ Message stats ++++++++++++"
		puts "Stamps: ".ljust(10) + res[user][:msg_stats][:stamp_nr].to_s.rjust(5)
		puts "Photos: ".ljust(10) + res[user][:msg_stats][:photo_nr].to_s.rjust(5)
		puts "Videos: ".ljust(10) + res[user][:msg_stats][:vid_nr].to_s.rjust(5)
		puts "Text: ".ljust(10) + res[user][:msg_stats][:text_nr].to_s.rjust(5)
		puts "Total: ".ljust(10) + (res[user][:msg_stats][:stamp_nr] + res[user][:msg_stats][:photo_nr] + res[user][:msg_stats][:text_nr]).to_s.rjust(5) + "\n"
		puts "\n++++++++++++ Reply Time stats ++++++++++++\n"
		puts "Average reply time (msg w/ ?)".ljust(40) + get_string_time(reply_time_res[user][:norm]).rjust(5)
		puts "Average reply time (no rs)".ljust(40) + get_string_time(reply_time_res[user][:dumb]).rjust(5)
		puts ("Average reply time (rs %dhr)" % wihtin_hr).ljust(40) + get_string_time(reply_time_res[user][:short]).rjust(5)
	end
end

def analyze_lines(chat, within_hr=6, show=true)
	msg_amt = chat.length
	words = {}
	sender_message = Hash.new()
	stickers = 0
	images = 0
	videos = 0
	chat_txt = 0
	prev_sender = nil
	# DateTime objects
	prev_msgtime_dumb = nil
	prev_msgtime_short = nil
	# Reply times
	reply_time_res = {}
	questions_asked = {}
	avg_reply_time = {}
	avg_dumb_reply_time = {}
	avg_short_reply_time = {}

	question_struct = Struct.new(:sender, :datetime)
	question = nil
	
	for ent in chat
		datetime = find_datetime(ent)
		sender = ent.LINE.sender
		#puts "Sender " + sender
		
		#Add all chats to an array in a hash, indexed by sender
		add_sender_data(sender, datetime, ent, sender_message)
		
		#Add all words to hash
		if ent.LINE.type == "m"
			for word in ent.LINE.msg.split
				add_word_data(word, words)
			end
		end

		# Count # of messages pr type
		if ent.LINE.type == "s"
			stickers += 1
		elsif ent.LINE.type == "p"
			images += 1
		elsif ent.LINE.type == "v"
			videos += 1
		else
			chat_txt += 1
		end
		

		# Find reply time for current question and new average
		if question != nil and question.sender != sender
			reply_time = get_reply_time(datetime, question.datetime)
			# puts "Norm %s" % sender

			avg_reply_time[sender] = add_reply_time(avg_reply_time[sender], reply_time)
			question = nil
		end

		# Set question asked
		if ent.LINE.msg.include? "?" and question == nil
			question = question_struct.new(sender, datetime)
			# Count questions asked
			if questions_asked[sender] == nil
				questions_asked[sender] = 1
			else
				questions_asked[sender] += 1
				#puts questions_asked[sender]
			end
		end


		# dumb logic
		if prev_sender != nil && prev_sender != sender
			reply_time = get_reply_time(datetime, prev_msgtime_dumb)
			#puts "Dumb %s" % sender
			avg_dumb_reply_time[sender] = add_reply_time(avg_dumb_reply_time[sender], reply_time)
			#puts " Dumb " + sender + " - " + avg_dumb_reply_time[sender].to_s
			#Reset timer
			prev_msgtime_dumb = datetime
		end

		# short logic
		if prev_sender != nil && prev_sender != sender
			reply_time = get_reply_time(datetime, prev_msgtime_short)
			# If reply within X hours
						   #min #hr  #X hrs
			if reply_time < (60 * 60 * within_hr)
				#puts "Short %s" % sender
				avg_short_reply_time[sender] = add_reply_time(avg_short_reply_time[sender], reply_time)
				#puts "Short "+ sender + " - " + avg_short_reply_time[sender].to_s
			end

			#Reset timer
			prev_msgtime_short = datetime	
		end

		# Set previous sender
		prev_sender = sender
		
		# Set previous time dumb & short, if first run
		if prev_msgtime_dumb == nil
			prev_msgtime_dumb = datetime
			prev_msgtime_short = datetime
		end
			
	end
	
	word_stats = {uniq:0, most:[], most_nr:0, least:[], sorted:nil}
	#Extract data for all users
	extract_word_stats(words, word_stats)

	res = analyze_pr_sender(sender_message)

	# Calculate total distribution of messages
	percent_dist = {}
	res.each_key do |user|
		percent_dist[user] = ((res[user][:msg_stats][:tot_nr].to_f / msg_amt )* 100).to_f

		if !avg_reply_time.has_key?(user)
			avg_reply_time[user] = -1
		end

		if !avg_short_reply_time.has_key?(user)
			avg_short_reply_time[user] = -1
		end
		if !avg_dumb_reply_time.has_key?(user)
			avg_dumb_reply_time[user] = -1
		end

		reply_time_res[user] = {norm:0, dumb:0, short:0}
		reply_time_res[user][:norm] = analyze_reply_time(avg_reply_time[user])
		reply_time_res[user][:dumb] = analyze_reply_time(avg_dumb_reply_time[user])
		reply_time_res[user][:short] = analyze_reply_time(avg_short_reply_time[user])

		#puts "%s - %d" % [user, avg_reply_time[user]]
	end

	if show
		printout(words, stickers, images, videos, chat_txt, msg_amt, res, percent_dist, reply_time_res, within_hr, questions_asked)
	end
end

def analyze(filecontents, within_hr=12, show=true)
	chat=Array.new()
	date=""
	# Jump to beginning of history
	filecontents.shift(3)
	for line in filecontents
		# Get date
		if line.start_with?(/(\w{3}), /)
			date_raw = line.chomp()
			#puts "Date: "+date_raw
			date = date_raw.match(DATE_FORMAT) { |m| DATE_STR.new(*m.captures) }

		#Multiline support handling
		elsif not line.start_with?(/\d{1,2}:\d{2}/) and not /\S/ !~ line
			chat[-1].LINE.msg += "\n"+line.chomp()

		# Extract data
		elsif not /\S/ !~ line
			tmp = ChatEntr.new(extract(line), date)
			chat.push(tmp)
		end
	end

	analyze_lines(chat, within_hr, show)
end


LINE = Struct.new(:time, :sender, :msg, :type)
FORMAT = /(\d{1,2}:\d{2})\s?(\w*\s?\w*)\s?(.*)/

# Old format
#DATE_STR = Struct.new(:year, :month, :day, :weekday)
DATE_STR = Struct.new(:weekday, :day, :month, :year)
DATE_FORMAT = /(\w{3}), (\d{2})\/(\d{2})\/(\d{4})/

ChatEntr = Struct.new(:LINE, :date)

if ARGV.length  < 1
	puts "Usage: analyze.rb <full_path_chat_file>"
else
	for file in ARGV
		filecontents = readfile(file)
		analyze(filecontents, 6)
	end
end