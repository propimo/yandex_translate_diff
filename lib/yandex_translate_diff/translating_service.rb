module Translator
  class TranslatingService

    def initialize(translator)
      @translator = translator
    end

    # Перевести информацию, хранящуюся в поле класса, с русского на английский язык
    # @param objects [Enumerable] набор объектов, в которых нужно перевести поле
    # @param attribute_name [String] имя поля, которое необходимо перевести
    # @param from [String] язык, с которого перевести - русский по умолчанию
    # @param to [String] язык, на который перевести - английский по умолчанию
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
        if object.send(attribute_name_to).blank? || @translator.lang?(object.send(attribute_name_to), lang: from)
          begin

            # Перевести информацию, хранящуюся в поле на русском, и поместить ее в поле с англоязычной информацией
            translated_text = @translator.translate(object.send(attribute_name_from))

            object.update("#{autotranslated_attribute}": true,
                          "#{attribute_name_to}": translated_text) if translated_text.present?

            count += 1
            p "------[#{count}] #{objects.name} with id #{object.id} has been translated------"
          rescue Translator::YandexTranslator::DailyQuotaExceeded => d
            p d.message
            break
          rescue Translator::YandexTranslator::EmptyText => e
            p e.message
            break
          rescue Translator::YandexTranslator::WrongLanguage => w
            p w.message
            break
          end
        end
      end
    end
  end
end
