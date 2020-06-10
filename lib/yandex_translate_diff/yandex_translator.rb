require 'yandex-translator'
require 'pragmatic_segmenter'
require 'punkt-segmenter'
require 'diffy'

# Класс для перевода текста
module Translator

  class YandexTranslator

    MONTH_LIMIT = 10_000_000 # Количество бесплатно переводимых символов в месяц
    DAY_LIMIT = MONTH_LIMIT / 31 # Количество бесплатно переводимых символов в день

    DELETED_SENTENCE_REGEXP = /^\-/ # Удаленное предложение из текста в diff
    ADDED_SENTENCE_REGEXP = /^\+/ # Добавленное предложение в текст в diff

    def initialize()
      @translator = Yandex::Translator.new(key)

      # Количество переведенных символов за день
      @day_counter = 0
    end

    # Парсит текст на предложения и переводит непереведенные
    # @param text [String] текст для перевода
    # @param from [String] язык, с которого перевести - русский по умолчанию
    # @param to [String] язык, на который перевести - английский по умолчанию
    # @return [String] массив переведенных предложений
    def translate(text, from: 'ru', to: 'en', format: 'plain')

      # Проверить, способен ли переводчик перевести на заданные языки
      raise SameLanguages if from == to
      raise WrongLanguage unless @translator.langs.include?("#{from}-#{to}")

      sentences = get_sentences(text).compact

      sentences.reduce('') do |memo, sentence|
        memo << (lang?(sentence, lang: from) ? translate_sentence(sentence, from: from, to: to, format: format) : sentence) + " "
      end
    end

    # Определяет язык текста и сравнивает с заданным языком
    # @param text [String] текст
    # @param lang [String] язык, с которым сверяем
    # @return [Boolean] соответствие заданного языка языку текста
    def lang?(text, lang: 'en')
      return @translator.detect(text) == lang if text.size != 0
      false
    end

    # Определяет язык текста
    # @param text [String] текст
    # @return [String] язык текста
    def lang(text)
      return @translator.detect(text) if text.size != 0
      false
    end

    # Определяет доступные языки для переводчика
    # @return [String] языки, с которых и на которые доступен перевод
    def langs()
      @translator.langs()
    end

    # Переводит предложение с одного на другой заданный языки
    # @param sentence [String] предложение для перевода
    # @param from [translatorString] язык, с которого перевести - русский по умолчанию
    # @param to [String] язык, на который перевести - английский по умолчанию
    # @return [String] переведенное предложение
    def translate_sentence(sentence, from: 'ru', to: 'en', format: 'plain')

      # Перевести предложение, если лимит переводимых символов не превышен и языки заданы верно
      begin
        update_counter(sentence.length)
        @translator.translate(sentence, from: from, to: to, format: format)
      rescue DailyQuotaExceeded => d
        raise d
      rescue WrongLanguage => w
        raise w
      rescue SameLanguages => s
        raise s
      end
    end

    # Обновляет счетчик символов в день
    # @param signs_count [Integer] количество символов, которые необходимо перевести
    # @return [Integer] текущий счетчик
    def update_counter(signs_count)

      # Если количество переведенных символов не позволяет перевести еще - выдать сообщение об ошибке
      @day_counter += signs_count
      raise DailyQuotaExceeded if (@day_counter) >= DAY_LIMIT
      @day_counter
    end

    # Парсит текст на предложения
    # @param text [String] текст, который нужно разбить на предложения
    # @return Array[String] массив предложений
    def get_sentences(text)
      return if text.size == 0
      Punkt::SentenceTokenizer
          .new(text)
          .sentences_from_text(text, output: :sentences_text)
    end

    def sentences_to_diff(sentences)
      return if sentences.size == 0
      get_sentences(sentences).join("\n") + "\n"
    end

    # Обновляет перевод текста после его изменения
    # @param original_past [String] прежний текст
    # @param original_new [String] измененный текст, перевод которого нужно обновить
    # @param translated_past [String] перевод текста до его изменений
    # @return [String] обновленный перевод текста
    def update_translation(original_past, original_new, translated_past, format: 'plain', from: 'ru', to: 'en')

      # Подготовить тексты для обработки
      formatting_for_update(original_past, original_new, translated_past)

      # Получить разницу оригинальных текстов
      diffs = get_diffs(original_past, original_new)
      right_diff = diffs[:right_diff]
      left_diff = diffs[:left_diff]

      # Получить массив предложений уже переведенного текста
      translated_text = get_sentences(translated_past)

      return translate(original_new, format: format, from: from, to: to) if translated_text.blank?

      # Обновить переведенный текст
      diff_size =
          if right_diff.size > left_diff.size
            right_diff.size
          else
            left_diff.size
          end

      index = 0

      # Для каждого предложения из разницы оригиналов
      (0..diff_size).each do |diff_index|

        # Обновить текст: удалить удаленные, перевести и добавить новые предложения
        deleted = delete_sentence(diff_index, left_diff, translated_text, index)
        added = add_sentence(diff_index, right_diff, translated_text, index)

        index = index - 1 if deleted
        index = index + 1 if added

        index = index + 1
      end

      translated_text.join(" ")
    end

    # Находит удаленные и добавленные предложения, сравнив два текста
    # @param past_text [String] прежний текст
    # @param new_text [String] измененный текст
    # @return [JSON] массив удаленных и массив добавленных предложений
    def get_diffs(past_text, new_text)

      # Разбить новый и старый русский текст на предложения через \n
      tmp_new = sentences_to_diff(new_text)
      tmp_old = sentences_to_diff(past_text)

      # Получить массив измененных(удаленных) и неизмененных предложений
      left_diff = Diffy::SplitDiff.new(tmp_old, tmp_new).left.split("\n")

      # Получить массив добавленных и неизмененных предложений
      right_diff = Diffy::SplitDiff.new(tmp_old, tmp_new).right.split("\n")

      { left_diff: left_diff, right_diff: right_diff }
    end

    # Обрабатывает тексты для дальнейшего обновления перевода
    # @param original_past [String] прежний текст
    # @param original_new [String] измененный текст, перевод которого нужно обновить
    # @param translated_past [String] перевод текста до его изменений
    def formatting_for_update(original_past, original_new, translated_past)

      # Убрать </p> с конца текста
      original_new.chomp!('</p>')
      original_past.chomp!('</p>')

      # Заменить специальные символы
      [original_past, original_new, translated_past]
          .select(&:present?)
          .each do |text|
                  text.gsub!('&nbsp;', ' ')
                  Nokogiri::HTML.parse(text)
                end
    end

    # Удаляет предложение из текста, если оно было удалено в оригинале
    # @param diff_index [Integer] позиция предложения в массиве удаленных и неизмененных предложений
    # @param left_diff [Array] массив удаленных и неизмененных предложений
    # @param index [Integer] позиция предложения в обновляемом тексте
    # @param text [Array] текст, который нужно удалить
    # @return успешность операции: удалено / не удалено
    def delete_sentence(diff_index, left_diff, text, index)
      return false if text.size == 0 || index>text.size || diff_index>left_diff.size || left_diff[diff_index] !~ DELETED_SENTENCE_REGEXP

      text.delete(text[index])
      true
    end

    # Переводит и добавляет в текст предложение по позиции
    # @param diff_index [Integer] позиция предложения в массиве добавленных и неизмененных предложений
    # @param right_diff [Array] массив добавленных и неизмененных предложений
    # @param index [Integer] позиция предложения
    # @param text [Array] текст, в который нужно добавить предложение
    # @param from [String] язык, с которого перевести - русский по умолчанию
    # @param to [String] язык, на который перевести - английский по умолчанию
    # @return успешность операции: добавлено / не добавлено
    def add_sentence(diff_index, right_diff, text, index, from: 'ru', to: 'en')
      return false if diff_index>right_diff.size || right_diff[diff_index] !~ ADDED_SENTENCE_REGEXP

      # Выделить новое предложение
      diff_sentence = right_diff[diff_index]

      sentence_to_translate = diff_sentence[1, diff_sentence.size]

      # Перевести
      sentence_to_add = translate_sentence(sentence_to_translate, from: from, to: to)

      # Вставить перевод нового предложения
      if text.size == 0
        text.push(sentence_to_add)
      else
        text.insert(index, sentence_to_add)
      end

      p text
      true
    end

    # Ошибка превышенного допустимого количества символов в день
    class DailyQuotaExceeded < StandardError
      def initialize(msg: 'Daily limit is exceeded')
        super(msg)
      end
    end

    # Ошибка неверных входных данных
    class EmptyText < StandardError
      def initialize(msg: 'Can\'t be translated: text is empty')
        super(msg)
      end
    end

    # Ошибка недопустимого заданного языка
    class WrongLanguage < StandardError
      def initialize(msg: 'Can\'t be translated: languages are incorrect')
        super(msg)
      end
    end

    # Ошибка недопустимого заданного языка
    class SameLanguages < StandardError
      def initialize(msg: 'The text is already translated')
        super(msg)
      end
    end
  end
end
