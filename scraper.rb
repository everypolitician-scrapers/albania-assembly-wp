#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'wikidata'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def wikidata(title)
  return {} if title.to_s.empty?

  wd = Wikidata::Item.find_by_title title 
  return {} unless wd


  property = ->(elem, attr='title') { 
    prop = wd.property(elem) or return
    prop.send(attr)
  }

  fromtime = ->(time) { 
    return unless time
    DateTime.parse(time.time).to_date.to_s 
  }

  # party = P102
  # freebase = P646
  return { 
    wikidata: wd.id,
    family_name: property.('P734'),
    given_name: property.('P735'),
    image: property.('P18', 'url'),
    gender: property.('P21'),
    birth_date: fromtime.(property.('P569', 'value')),
  }
end

def scrape_list(url)
  noko = noko_for(url)

  noko.xpath('//table[.//th[contains(.,"Party")]]').each do |ctable|
    constituency = ctable.xpath('preceding::h3/span[@class="mw-headline"]').last.text
    ctable.xpath('.//tr[td]').each do |tr|
      tds = tr.css('td')
      data = { 
        name: tds[1].text.tidy,
        party: tds[2].css('a').first.text.tidy,
        wikipedia: tds[1].xpath('.//a[not(@class="new")]/@href').text,
        wikipedia_title: tds[1].xpath('.//a[not(@class="new")]/@title').text,
        constituency: constituency,
        term: '8',
        source: url,
      }
      data[:wikipedia] = URI.join('https://en.wikipedia.org/', data[:wikipedia]).to_s unless data[:wikipedia].to_s.empty?
      data.merge!  wikidata( data[:wikipedia_title] )
      puts data
      ScraperWiki.save_sqlite([:name, :constituency], data)
    end
  end
end

scrape_list('https://en.wikipedia.org/wiki/List_of_members_of_the_Assembly_of_the_Republic_of_Albania_(2009%E2%80%93present)')
