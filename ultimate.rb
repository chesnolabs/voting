# encoding: utf-8

require 'mechanize'
require 'csv'


puts "Фракційний скрипт вітає вас. Щоб зупинити його, натисніть Ctrl+C"
sleep 1
puts "Введіть перше число" 
id1 = gets.chomp
until  id1 =~ /\A\d+\z/ 
  puts "Це не число. Давай ще раз"
  id1 = gets.chomp
end

puts "А тепер друге" 
id2 = gets.chomp
until  id2 =~ /\A\d+\z/ 
  puts "Чувак, ЧИСЛО!"
  id2 = gets.chomp
end


agent = Mechanize.new
kods = *(id1..id2)
fraks = []
nards = []
noms = []


bag_of_dicks = []
CSV.foreach("deputies_ids.csv") {|row| bag_of_dicks << row}


kods.each do |id|
  begin
  page = agent.get("http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos_print?g_id="+id.to_s+"&vid=1")

  n = page.search('tr').length-1
  
  element = page.search('tr')[1].children.children
  day = element[4].text.gsub(/\n/, "").match(/від .{10}/).to_s.gsub(/від/,'')
  time = element[4].text.gsub(/\n/, "")[-8,8]
      
  utime=day+" "+time
  thisid = DateTime.strptime(utime, " %d.%m.%Y %H:%M:%S").to_time.to_i
  fraks[0] = thisid
  noms[0] = thisid
  noms[1] = day
  noms[2] = time
  noms[3] = element[6].text.gsub(/\n/, "")
        CSV.open("#{id1}_#{id2}_ids.csv", "ab", {:col_sep => "\t"}) do |data|
        data << noms
      end
  
  
  arr = *(2..n)

  for i in arr
    if page.search('tr')[i].children.size > 1
      arow = page.search('tr')[i].text.gsub(/\n/,',').split(',')
      
      bag_of_dicks.each do |dick|
        if dick.include?(arow[0])
         nards[0] = thisid
          nards[1] = dick[1]
          nards[2] = arow[1]
          CSV.open("#{id1}_#{id2}_MPs.csv", "ab") do |data|
           data << nards
          end
        elsif dick.include?(arow[2])
          nards[0] = thisid
          nards[1] = dick[1]
          nards[2] = arow[3]
          CSV.open("#{id1}_#{id2}_MPs.csv", "ab") do |data|
           data << nards
          end
        end
      end
    elsif page.search('tr')[i].children.size == 1 && page.search('tr')[i].text.size > 2
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
      element2 = page.search('tr')[i].text.split(/\n/)[1]
      fraks[2] = element2.match(/За - \d*/).to_s.gsub(/\n/, "")
      fraks[3] = element2.match(/Проти - \d*/).to_s.gsub(/\n/, "")
      fraks[4] = element2.match(/Утрималися - \d*/).to_s.gsub(/\n/, "")
      fraks[5] = element2.match(/Не голосували - \d*/).to_s.gsub(/\n/, "")
      fraks[6] = element2.match(/Відсутні - \d*/).to_s.gsub(/\n/, "")
      CSV.open("#{id1}_#{id2}_frakciji.csv", "ab") do |data|
        data << fraks
      end
      
    end
  end
  sleep 1
  puts thisid
  rescue
    next
  end
end
