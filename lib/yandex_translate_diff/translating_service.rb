module YandexTranslateDiff
  class TranslatingService
    def initialize(translator)
      @translator = translator
    end

    # Перевести информацию, хранящуюся в поле класса, с русского на английский язык
    # @param objects [Enumerable] набор объектов, в которых нужно перевести поле
    # @param attribute_name [String] имя поля, которое необходимо перевести
    # @param from [String] язык, с которого перевести - русский по умолчанию
    # @param to [String] язык, на который перевести - английский по умолчанию
    # @param format [String] формат текста: html-текст в html-формате, plain-обычный (по умолчанию)
    def translate(objects, attribute_name:, from: 'ru', to: 'en', format: 'plain')
      # Создать строки - имена полей на соответственных языках
      attribute_name_from = "#{attribute_name}_#{from}"
      attribute_name_to = "#{attribute_name}_#{to}"

      # Флаг автоматического перевода поля
      autotranslated_attribute = "autotranslated_#{attribute_name_to}"

      # Количество переведенных объектов
      count = 0

      # Для каждого объекта, поле на русском языке которого не пустое
      objects.find_all { |obj| obj.send(attribute_name_from).present? }.each do |object|
        # Выбрать объекты, в которых необходимо осуществить перевод: если отсутствует перевод на заданный язык
        next unless object.send(attribute_name_to).blank? || @translator.lang?(object.send(attribute_name_to), lang: from)

        begin
          # Перевести информацию, хранящуюся в поле на русском, и поместить ее в поле с англоязычной информацией
          translated_text = @translator.translate(object.send(attribute_name_from), format)

          if translated_text.present?
            object.update("#{autotranslated_attribute}": true,
                          "#{attribute_name_to}": translated_text)
          end

          count += 1
          p "------[#{count}] #{objects.name} with id #{object.id} has been translated------"
        rescue YandexTranslateDiff::YandexTranslator::DailyQuotaExceeded => e
          p e.message
          break
        rescue YandexTranslateDiff::YandexTranslator::EmptyText => e
          p e.message
          break
        rescue YandexTranslateDiff::YandexTranslator::WrongLanguage => e
          p e.message
          break
        rescue YandexTranslateDiff::YandexTranslator::SameLanguages => e
          p e.message
          break
        end
      end
    end
  end
end
