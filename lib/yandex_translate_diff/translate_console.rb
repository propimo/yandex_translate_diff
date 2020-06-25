require 'thor'
require_relative 'languages.rb'
require_relative 'yandex_translator'

module YandexTranslateDiff
  class TranslateConsole < Thor

    USAGE = <<-LONGDESC
    Simple client for Yandex Translate API.
    Usage:
      transl                             # displays usage
      transl lang Hello world            # displays the language of the sentence
      transl list                        # displays the list of supported languages
      transl en:ru Hello world           # translates from English to Russian
      transl ru Hello world              # translates to Russian from auto-detected language
    LONGDESC

    desc 'lang', 'figures out the language'
    def lang(text)
      translator = YandexTranslateDiff::YandexTranslator.new

      short_language = translator.lang(text)
      language = LANGUAGES.detect { |k, _v| k == short_language }

      puts "Text is written in #{language[1]}"
    end

    desc 'list', 'displays the list of supported languages.rb'
    def list
      translator = YandexTranslateDiff::YandexTranslator.new
      puts 'Available languages:', translator.langs
    end

    desc 'translate text', 'translates the text'
    def translate(from_lang, to_lang, text)
      translator = YandexTranslateDiff::YandexTranslator.new
      translated_text = translator.translate(text, from: from_lang, to: to_lang)

      puts "Translation: #{translated_text}"
    end

    desc 'translate to ru', 'translates the text to russian'
    def translate_to(to_lang, text)
      translator = YandexTranslateDiff::YandexTranslator.new
      current_language = translator.lang(text)
      translated_text = translator.translate(text, from: current_language, to: to_lang)

      puts "Translation: #{translated_text}"
    end
  end
end
