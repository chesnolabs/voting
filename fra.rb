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
arr = []

kods.each do |id|
  page = agent.get("http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos_print?g_id="+id.to_s+"&vid=1")
  n = page.search('tr').length-1
  arr[1] = page.search('tr')[1].children.children[6].text.gsub(/\n/, "")
  arr[2] = page.search('tr')[1].children.children[4].text.gsub(/\n/, "").match(/від .{10}/)
  arr[3] = page.search('tr')[1].children.children[4].text.gsub(/\n/, "")[-8,8]
  
  arr2 = *(2..n)
  for i in arr2 
    if page.search('tr')[i].children.size == 1 && page.search('tr')[i].text.size > 2
      case page.search('tr')[i].text
      when /Фракція.*України/ 
        arr[0] = page.search('tr')[2].text.match(/Фракція.*України/).to_s.gsub(/\n/, "")
      when /Фракція.*Кличка/
        arr[0] = "Фракція Політичної партії УДАР"
      when  /Фракція.*Свобода/
        arr[0] = "Фракція Всеукраїнське об'єднання Свобода" 
      when /Позафракційні/
        arr[0] = "Позафракційні"
      end
      arr[4] = page.search('tr')[i].text.split(/\n/)[1].match(/За - \d*/).to_s.gsub(/\n/, "")
      arr[5] = page.search('tr')[i].text.split(/\n/)[1].match(/Проти - \d*/).to_s.gsub(/\n/, "")
      arr[6] = page.search('tr')[i].text.split(/\n/)[1].match(/Утрималися - \d*/).to_s.gsub(/\n/, "")
      arr[7] = page.search('tr')[i].text.split(/\n/)[1].match(/Не голосували - \d*/).to_s.gsub(/\n/, "")
      arr[8] = page.search('tr')[i].text.split(/\n/)[1].match(/Відсутні - \d*/).to_s.gsub(/\n/, "")
      CSV.open("#{id1}_#{id2}_frak.csv", "ab", {:col_sep => "\t"}) do |data|
        data << arr
      end
    end
  end
  puts id 
  sleep 2
end
