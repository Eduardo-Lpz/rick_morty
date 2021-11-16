# frozen_string_literal: true

require_relative "rick_and_morty/version"
require "net/http"
require "json"
require "set"

module RickAndMorty
  class Characters
    BASE_URI = "https://rickandmortyapi.com/api/character/"
    def histogram
      count = set_count
      threads = []
      character_data = []
      species = Set[]

      # (1..count).each do |id|
      (1..100).each do |id|
        threads << Thread.new {
          data = get_character_data(id)
          if data.has_value?("Dead")
            character_data.push(data)
            species.add(data["species"])
          end
        }
      end

      threads.each(&:join)
      serialize(species, character_data, count)
    end

    private

    def set_count
      response = Net::HTTP.get(URI(BASE_URI))
      JSON.parse(response).dig("info", "count")
    end

    def get_character_data(id)
      response = Net::HTTP.get(URI(BASE_URI + id.to_s))
      JSON.parse(response).slice("status", "species")
    end

    def serialize(species, character_data, count)
      deaths_data = {}

      species.each do |s|
        deaths_data[s.to_s] = character_data.count { |data| data.has_value?(s.to_s) }
      end

      total_deaths = deaths_data.values.reduce(:+)

      deaths_data.each do |specie, deaths|
        puts "#{specie}: " + "\u{1f480}" * deaths
      end
      puts "Total deaths: #{total_deaths}\nTotal characters: #{count}"
      puts "#{total_deaths.to_f * 100 / count} % has died"
    end
  end

  def self.characters
    RickAndMorty::Characters.new
  end
end
