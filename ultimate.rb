# encoding: utf-8

require 'mechanize'
require 'csv'
require 'json'

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
  elsif a < Date.strptime("12.12.2012","%d.%m.%Y")
    puts "Дані раніше 12.12.2012 не збираються"
    abort
  elsif b > Date.strptime("31.12.2014","%d.%m.%Y")
    puts "За 2015 і пізніше даних ще нема, ви чо"
    abort
  end
  
end


date1=ARGV[0]
date2=ARGV[1]

validate_presence(date1)
validate_presence(date2)

a = validate_format(date1)
b = validate_format(date2)

validate_sequence(a,b)

agent = Mechanize.new

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
      
      
kods.each do |id|
  begin
  page = agent.get("http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos_print?g_id="+id.to_s+"&vid=1")

  n = page.search('tr').length-1  
  
  element = page.search('tr')[1].children.children
  day = element[5].text.gsub(/\n/, "").match(/від .{10}/).to_s.gsub(/від/,'')
  time = element[5].text.gsub(/\n/, "")[-8,8]
      
  utime=day+" "+time
  thisid = DateTime.strptime(utime, " %d.%m.%Y %H:%M:%S").to_time.to_i
  fraks[0] = thisid
  noms[0] = thisid
  noms[1] = day
  noms[2] = time
  noms[3] = element[8].text.gsub(/\n/, "")
  CSV.open("#{date1}_#{date2}_ids.csv", "ab", {:col_sep => "\t"}) do |data|
    data << noms
  end
    
  arr = *(2..n)

  for i in arr
    if page.search('tr')[i].children.size > 2
      arow = page.search('tr')[i].text.gsub(/\n/,',').split(',')
      
      bag_of_dicks.each do |dick|
        if dick.include?(arow[1])
         nards[0] = thisid
          nards[1] = dick[1]
          nards[2] = arow[2]
          CSV.open("#{date1}_#{date2}_MPs.csv", "ab") do |data|
           data << nards
          end
        elsif dick.include?(arow[3])
          nards[0] = thisid
          nards[1] = dick[1]
          nards[2] = arow[4]
          CSV.open("#{date1}_#{date2}_MPs.csv", "ab") do |data|
           data << nards
          end
        end
      end
    elsif page.search('tr')[i].children.size == 2 && page.search('tr')[i].text.size > 2
      case page.search('tr')[i].text
      when /Фракція.*регіонів/
        fraks[1] = 3
      when /Група.*європейська/
        fraks[1] = 8
      when /Група.*розвиток/
        fraks[1] = 7
      when /Фракція.*Комуністичної/
        fraks[1] = 4
	  when /Фракція.*Батьківщина/
        fraks[1] = 1
	  when /Фракція.*Кличка/
        fraks[1] = 2
      when  /Фракція.*Свобода/
        fraks[1] = 6
      when /стабільність/
        fraks[1] = 9
      when /Позафракційні/
        fraks[1] = 5
      end
      element2 = page.search('tr')[i].text.split(/\n/)[2]
      fraks[2] = element2.match(/За - \d*/).to_s.gsub(/\n/, "").gsub(/За\s-\s/,"")
      fraks[3] = element2.match(/Проти - \d*/).to_s.gsub(/\n/, "").gsub(/Проти\s-\s/,"")
      fraks[4] = element2.match(/Утрималися - \d*/).to_s.gsub(/\n/, "").gsub(/Утрималися\s-\s/,"")
      fraks[5] = element2.match(/Не голосували - \d*/).to_s.gsub(/\n/, "").gsub(/Не\sголосували\s-\s/,"")
      fraks[6] = element2.match(/Відсутні - \d*/).to_s.gsub(/\n/, "").gsub(/Відсутні\s-\s/,"")
      CSV.open("#{date1}_#{date2}_frakciji.csv", "ab") do |data|
        data << fraks
      end
      
    end
  end
  sleep 1
  puts id
  rescue
    next
  end
end
