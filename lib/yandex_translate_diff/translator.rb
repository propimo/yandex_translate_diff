require 'thor'
require_relative 'languages.rb'
require_relative 'yandex_translator'

module Translator
  class TranslateConsole < Thor
    desc 'detect language', 'figures out the language'
    def lang(text)
      translator = Translator::YandexTranslator.new

      short_language = translator.lang(text)
      language = LANGUAGES.detect { |k, _v| k == short_language }

      puts "Text is written in #{language[1]}"
    end

    desc 'list', 'displays the list of supported languages.rb'
    def list
      translator = Translator::YandexTranslator.new
      puts 'Available languages:', translator.langs
    end

    desc 'translate text', 'translates the text'
    def translate(from_lang, to_lang, text, format)
      translator = Translator::YandexTranslator.new
      translated_text = translator.translate(text, from: from_lang, to: to_lang, format: format)

      puts "Translation: #{translated_text}"
    end

    desc 'translate to ru', 'translates the text to russian'
    def translate_ru(text, format: 'plain')
      translator = Translator::YandexTranslator.new
      current_language = translator.lang(text)
      puts current_language
      translated_text = translator.translate(text, from: current_language, to: 'ru', format: format)

      puts "Translation: #{translated_text}"
    end
  end
end

Translator::TranslateConsole.start(ARGV)
