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

def scrape_list(url)
  noko = noko_for(url)

  noko.xpath('//table[.//th[contains(.,"Party")]]').each do |ctable|
    constituency = ctable.xpath('preceding::h3/span[@class="mw-headline"]').last.text
    ctable.xpath('.//tr[td]').each do |tr|
      tds = tr.css('td')
      data = { 
        name: tds[1].css('a').first.text.tidy,
        party: tds[2].css('a').first.text.tidy,
        wikiname: tds[1].xpath('.//a[not(@class="new")]/@title').text,
        constituency: constituency,
        term: '7',
        source: url,
      }
      ScraperWiki.save_sqlite([:name, :constituency], data)
    end
  end
end

scrape_list('https://en.wikipedia.org/wiki/List_of_members_of_the_parliament_of_Albania,_2009%E2%80%932013')
