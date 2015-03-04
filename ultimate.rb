# encoding: utf-8

require 'mechanize'
require 'csv'
require 'json'

BAG_SIZE=432

class Validator

  def validate_presence (date)
    if date.nil?
      puts "При запуску треба ввести дві дати у форматі dd.mm.yyyy"
      abort
    end
  end

  def validate_format(date)
    begin
      Date.strptime(date,"%d.%m.%Y")
    rescue ArgumentError
      puts "Неправильний формат дати"
      abort
    end
  end

  def validate_sequence(a,b)
    if a > b
      puts "Дати не в тому порядку"
      abort
   # elsif a < Date.strptime("12.12.2012","%d.%m.%Y")
    #  puts "Дані раніше 12.12.2012 не збираються"
     # abort
    #elsif b > Date.strptime("31.12.2014","%d.%m.%Y")
     # puts "За 2015 і пізніше даних ще нема, ви чо"
      #abort
    end
  end
end



class Voting
  
  attr_reader :page
  
  def initialize(page)
    @page = page
  end
 
  def element 
    page.search('tr')[1].children.children
  end
 
  def day
    element[5].text.gsub(/\n/, "").match(/від .{10}/).to_s.gsub(/від/,'')
  end
  
  def time
    element[5].text.gsub(/\n/, "")[-8,8]
  end
  
  def thisid
    utime=day+" "+time
    DateTime.strptime(utime, " %d.%m.%Y %H:%M:%S").to_time.to_i
  end
  
  def title
    element[8].text.gsub(/\n/, "")
  end
  
  def gangs
    array_of_rows = page.search('tr')
    empty = array_of_rows.find_all { |r| r.text == " "}
    delimiters = empty.map { |e| array_of_rows.index(e)+1 }
    delimiters = delimiters.unshift(2)
    n = delimiters.size - 2
    gangs = Array.new
    a = *(0..n)
    for i in a
      gangs << array_of_rows.slice(delimiters[i]..delimiters[i+1])
    end
    gangs
  end
  
end

GANGS = {"ПОРОШЕНКА" => 1, "ФРОНТ" => 2, "Опозиційний"=> 3, "Позафракційні" => 4, "САМОПОМІЧ" => 5, 
"Ляшка"=> 6, "Воля" => 7, "Батьківщина" => 8, "розвиток" => 9}

date1=ARGV[0]
date2=ARGV[1]

validator = Validator.new

validator.validate_presence(date1)
validator.validate_presence(date2)

a = validator.validate_format(date1)
b = validator.validate_format(date2)

validator.validate_sequence(a,b)

dates_file=File.read("dates.json")
dates_hash = JSON.parse(dates_file)

kods = Array.new

aods = (a..b).map{ |date| date.strftime("%d %m %Y").split(' ')}

aods.each do |aod|
  if dates_hash[aod[2]][aod[1]]
    if dates_hash[aod[2]][aod[1]][aod[0]]
      array = eval "(#{dates_hash[aod[2]][aod[1]][aod[0]]}).to_a"
      kods << array
    end
  end
end

kods.flatten!

fraks = []
nards = []
noms = []

bag_of_dicks = []
CSV.foreach("deputies_ids.csv") {|row| bag_of_dicks << row}

CSV.open("#{date1}_#{date2}_MPs.csv", "ab") do |data|
  header = Array.new
  header[0] = "voting_ID"
  header[1] = "MP_ID"
  header[2] = "voting"
  header[3] = "faction_id"
  data << header
end

CSV.open("#{date1}_#{date2}_ids.csv", "ab", {:col_sep => "\t"}) do |data|
  header = Array.new
  header[0] = "voting_ID"
  header[1] = "date"
  header[2] = "time"
  header[3] = "title"
  data << header
end

CSV.open("#{date1}_#{date2}_frakciji.csv", "ab") do |data|
  header = Array.new
  header[0] = "voting_ID"
  header[1] = "faction_ID"
  header[2] = "for"
  header[3] = "against"
  header[4] = "abstain"
  header[5] = "did_not_vote"
  header[6] = "absent"
  data << header
end

agent = Mechanize.new

kods.each do |id|
  begin
 
  page = agent.get("http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos_print?g_id="+id.to_s+"&vid=1")
  
  voting = Voting.new(page)  
 
  thisid = voting.thisid
  
  noms[0] = thisid
  noms[1] = voting.day
  noms[2] = voting.time
  noms[3] = voting.title
  
  CSV.open("#{date1}_#{date2}_ids.csv", "ab", {:col_sep => "\t"}) do |data|
    data << noms
  end
  
  bag_of_dicks.pop until bag_of_dicks.size==BAG_SIZE
  
  voting.gangs.each do |gang|
    GANGS.keys.each do |key|
      if gang.first.text.match(key)
        fra_id = GANGS[key]
        fraks[0] = thisid
        fraks[1] = fra_id
        fraks[2] = gang[0].text.match(/За - \d*/).to_s.gsub(/\n/, "").gsub(/За\s-\s/,"")
        fraks[3] = gang[0].text.match(/Проти - \d*/).to_s.gsub(/\n/, "").gsub(/Проти\s-\s/,"")
        fraks[4] = gang[0].text.match(/Утрималися - \d*/).to_s.gsub(/\n/, "").gsub(/Утрималися\s-\s/,"")
        fraks[5] = gang[0].text.match(/Не голосували - \d*/).to_s.gsub(/\n/, "").gsub(/Не\sголосували\s-\s/,"")
        fraks[6] = gang[0].text.match(/Відсутні - \d*/).to_s.gsub(/\n/, "").gsub(/Відсутні\s-\s/,"")
        CSV.open("#{date1}_#{date2}_frakciji.csv", "ab") do |data|
          data << fraks
        end
        bag_of_dicks.pop unless bag_of_dicks.size == BAG_SIZE
        if fra_id == 8
          bag_of_dicks << ["Тимошенко Ю.В.", "26674"]
        elsif fra_id == 2
          bag_of_dicks << ["Тимошенко Ю.В.", "22705"]
        end
        gang.each do |row|
          arow = row.text.gsub(/\n/,',').split(',')
          bag_of_dicks.each_with_index do |dick, index|
            if dick.include?(arow[1])
              nards[0] = thisid
              nards[1] = dick[1]
              nards[2] = arow[2]
              nards[3] = fra_id
              CSV.open("#{date1}_#{date2}_MPs.csv", "ab") do |data|
                data << nards
              end
            elsif dick.include?(arow[3])
              nards[0] = thisid
              nards[1] = dick[1]
              nards[2] = arow[4]
              nards[3] = fra_id
              CSV.open("#{date1}_#{date2}_MPs.csv", "ab") do |data|
                data << nards
              end
            end
          end
        end
      end
    end
  end
  puts id
  
  sleep 2
  
  rescue
    next
  end
end
