require "thor"
require_relative 'languages.rb'
require_relative 'yandex_translator'

module Translator
  class TranslateConsole < Thor

    desc "hello NAME", "say hello to NAME"
    def hello(name)
      puts "Hello #{name}"
    end

    desc "detect language", "figures out the language"
    def lang text
      translator = Translator::YandexTranslator.new

      short_language = translator.lang(text)
      language = LANGUAGES.detect{ |k, v| k == short_language}

      puts "Text is written in #{language[1]}"
    end

    desc "list", "displays the list of supported languages.rb"
    def list
      translator = Translator::YandexTranslator.new
      puts "Available languages.rb:", translator.langs()
    end

    desc "translate text", "translates the text"
    def translate from_lang, to_lang, text, format
      translator = Translator::YandexTranslator.new
      translated_text = translator.translate(text, from:from_lang, to:to_lang, format: format)

      puts "Translation: #{translated_text}"
    end

  end
end

Translator::TranslateConsole.start(ARGV)

