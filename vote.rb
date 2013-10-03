# encoding: utf-8

require 'mechanize'
require 'csv'

puts "Депутатський скрипт вітає вас. Щоб зупинити його, натисніть Ctrl+C"
sleep 1
puts "Введіть дату початку у форматі dd.mm.yyyy" 
date1 = gets.chomp

until  date1 =~ /\A\d{2}\.\d{2}.\d{4}\z/ 
puts "Якась у вас дата неправильна. Спробуйте ще раз" 
date1 = gets.chomp
end

puts "Атлічно, а тепер дату кінця у такому ж форматі"
date2 = gets.chomp

until  date2 =~ /\A\d{2}\.\d{2}.\d{4}\z/ 
puts "Нє, не то. Спробуйте ще раз" 
date2 = gets.chomp
end
sleep 1

puts "Зараз відбудеться збір даних про голосування депутатів з #{date1} по #{date2}. 
Результат буде збережено в тій же папці, що і скрипт.
Не закривайте вікно терміналу, поки скрипт виконується. 
Якщо воно вам заважає, перекиньте його на інший воркспейс."
sleep 1

kodsall = *(2..455)
kods = kodsall.delete_if { |ko| [397, 230, 287, 220, 231, 228, 309, 265, 222].include? ko }
arr = []

kods.each do |kod|
  agent = Mechanize.new
  page = agent.get("http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_dep_gol_list_print?startDate="+date1+"&endDate="+date2+"&kod="+kod.to_s)
  arr[0] = page.search('tr')[1].text.strip.split(/\n/)[0] #name
  n = page.search('tr').length-1
  arr2 = *(4..n)
  for i in arr2 

    if page.search('tr')[i].children.size == 6
      arr[1] = page.search('tr')[i].children.children[0].text #номер
      arr[2] = page.search('tr')[i].children.children[1].text.strip.gsub(/\n/, "") #назва
      arr[3] = page.search('tr')[i].children.children[2].text.strip #голосування
      arr[4] = page.search('tr')[i+1].text.split(/\n/)[1].match(/\d.*/).to_s
      arr[5] = page.search('tr')[i+1].text.split(/\n/)[2].match(/За-\d*/).to_s
      if page.search('tr')[i-1].text.match(/\A\d{2}\.\d{2}.\d{4}\z/)
        arr[6] = page.search('tr')[i-1].text.match(/\A\d{2}\.\d{2}.\d{4}\z/)   
      end
      CSV.open("#{date1}_#{date2}_votes.csv", "ab", {:col_sep => "\t"}) do |data|
        data << arr
      end
    end
  end
  puts arr[0] + " is done"
  sleep 2
end
