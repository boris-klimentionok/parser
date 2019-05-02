#!/usr/bin/ruby
require 'curb' 
require 'nokogiri' 
require 'csv' 

def url_to_doc (url_of_doc)
http=Curl.get(url_of_doc)
return Nokogiri::HTML(http.body_str)
end
#Прогресбар
def progresline(procent)
symbcount=procent/2.5
spacecount=40-symbcount
linetext="#"*symbcount+ " "*spacecount
progreslinetext ="\e[#{32}mПарсинг страниц с товарами ["+linetext+"] "+procent.to_s+" % выполнено\e[0m  "
print progreslinetext + "\r"
end


url=ARGV[0];
filepath=ARGV[1];
result= Array[[]];

if ARGV.length != 2;
	puts "Не верно указаны параметры"
	puts "Использование:"
	puts "parser.rb <url> <output CSV file>"  
	puts url
	puts filepath
exit
end
#Определяет URL последней страницы категории 
lastpagehttp = Curl::Easy.perform(url+"?p=65000") do |curl|
  curl.head = true
  curl.follow_location = true
end
lastpage=lastpagehttp.last_effective_url.to_s


#Формирует список товаров
puts "Формирование списка таваров..."
productlist= Array[]
doc= url_to_doc (url)
productlist= doc.xpath("//*[contains(@id, 'product_list')]/li/div/div/div[1]/a/@href").to_a
k=2;
if lastpage.to_s!=url.to_s then
	while lastpage.to_s!=(url.to_s+"?p=#{k-1}") do
	doc= url_to_doc (url+"?p=#{k}")
	productlist=productlist+doc.xpath("//*[contains(@id, 'product_list')]/li/div/div/div[1]/a/@href").to_a
	k=k+1
	end 
end
puts "Найдено "+productlist.length.to_s+" товаров"
	
#Парсит страницы товаров
j=0 
while j < productlist.length  do
doc = url_to_doc(productlist[j])
productname=doc.xpath("//*[contains(@id, 'center_column')]/div/div/div[2]/div[2]/h1/text()").to_s
productimg=doc.xpath("//*[contains(@id,'bigpic')]/@src").to_s
	#Для страниц мультипродукта
	productcost=doc.xpath("//*[contains(@id,'attributes')]/fieldset/div/ul/li/label/span[2]/text()")
	productprop = doc.xpath("//*[contains(@id,'attributes')]/fieldset/div/ul/li/label/span[1]/text()")
	if productprop.length>0 then
		i=0
		res=Array[[]]
		while i < productprop.length  do
		res[i]=[productname.to_s+" "+productprop[i].to_s, productcost[i].to_s.chomp(" €/u") , productimg.to_s]			
		i +=1
		end
#Для остальных страниц
	else
	productcost=doc.xpath("//*[contains(@id,'our_price_display')]/text()")
	res= [[productname.to_s, productcost.to_s.chomp(" €"), productimg.to_s]]  
	end
if (result.length==1)&(j==0) then
result=res
else
result=result+res
end		

progresline(100*j/productlist.length)
	j +=1
	end
progresline(100)
puts


#Запись результата в CSV фаил
CSV.open(filepath,"wb") do |csv |
        csv << ["name", "price", "image"]   
	i=0	
	while i < result.length  do
	csv << result[i]
	i+=1
end
end
i=0




puts "Результат сохранен в "+ filepath
