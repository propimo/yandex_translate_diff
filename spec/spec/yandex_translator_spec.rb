require 'spec_helper'
require '../../yandex_translate_diff/lib/yandex_translate_diff/yandex_translator'

describe YandexTranslateDiff::YandexTranslator do

  before { @translator = YandexTranslateDiff::YandexTranslator.new }

  context "plain" do
    it "should translate correctly plain sentence ru-en" do
      expect(@translator.translate("Тестирование библиотеки."))
          .to eql("Testing of the library. ")
    end

    it "should translate correctly plain sentence en-ru" do
      expect(@translator.translate("Testing of the library.", from: 'en', to: 'ru'))
          .to eql("Тестирование библиотеки. ")
    end

    it "should translate correctly several plain sentences ru-en" do
      expect(@translator.translate("Тестирование библиотеки. Второй тест на русско - английский перевод.", from: 'ru', to: 'en'))
          .to eql("Testing of the library. The second test for Russian - English translation. ")
    end

    it "should translate correctly several plain sentences en-ru" do
      expect(@translator.translate("Testing of the library. Second test for english - russian translation.", from: 'en', to: 'ru'))
          .to eql("Тестирование библиотеки. Второй тест на англо - русский перевод. ")
    end
  end

  context "html" do
    it "should translate correctly plain sentence ru-en" do
      expect(@translator.translate("<b>Тестирование библиотеки.</b>", format: "html"))
          .to eql("<b>Testing of the library.</b> ")
    end

    it "should translate correctly plain sentence en-ru" do
      expect(@translator.translate("<i>Testing of the library.</i>", from: 'en', to: 'ru', format: "html"))
          .to eql("<i>Тестирование библиотеки.</i> ")
    end

    it "should translate correctly several plain sentences ru-en" do
      expect(@translator.translate("Тестирование <b>библиотеки</b>. Второй тест на русско - английский перевод.", from: 'ru', to: 'en', format: "html"))
          .to eql("Testing <b>of the library</b>. The second test for Russian - English translation. ")
    end

    it "should translate correctly several plain sentences en-ru" do
      expect(@translator.translate("Testing of the library. <b><i>Second test for english - russian translation.</i></b>", from: 'en', to: 'ru', format: "html"))
          .to eql("Тестирование библиотеки. <b><i>Второй тест на англо - русский перевод.</i></b> ")
    end
  end

  describe :delete_sentence do

    it "Should remove sentence on the position from text if it is marked with '-'" do
      text = ["Sam went to his family.", "He drunk a cup of tea."]
      expect(@translator.delete_sentence(1,[" Sam went to his family.", "-He drunk a cup of tea."], text, 1))
          .to eql(true)
      expect(text).to eql(["Sam went to his family."])
    end

    it "Should remove sentence on the position from processed text if it is marked with '-' and get the empty array" do
      text = ["He drunk a cup of tea."]
      expect(@translator.delete_sentence(1,["-Sam went to his family.", "-He drunk a cup of tea."], text, 0))
          .to eql(true)
      expect(text).to eql([])
    end

    it "Should return false due to the empty text" do
      text = []
      expect(@translator.delete_sentence(1,["-Sam went to his family.", "-He drunk a cup of tea."], text, 0))
          .to eql(false)
      expect(text).to eql([])
    end

    it "Should return false due to the empty list" do
      text = ["He drunk a cup of tea."]
      expect(@translator.delete_sentence(1,[""], text, 0))
          .to eql(false)
      expect(text).to eql(["He drunk a cup of tea."])
    end

    it "Should return false due to absence of '-'" do
      text = ["He drunk a cup of tea."]
      expect(@translator.delete_sentence(1,["-Sam went to his family.", "He drunk a cup of tea."], text, 0))
          .to eql(false)
      expect(text).to eql(["He drunk a cup of tea."])
    end
  end

  describe :add_sentence do

    it "Should add and translate sentence in the end from the list if it is marked with '+'" do
      text = ["Сэм отправился к своей семье."]
      expect(@translator.add_sentence(1,["+Sam went to his family.", "+He drunk a cup of tea."], text, 1, from: 'en', to: 'ru'))
          .to eql(true)
      expect(text).to eql(["Сэм отправился к своей семье.", "Он выпил чашку чая."])
    end

    it "Should add and translate sentence in the middle from the list if it is marked with '+'" do
      text = ["Сэм отправился к своей семье.", "Он выпил чашку чая."]
      expect(@translator.add_sentence(2,["Sam went to his family.", "He drunk a cup of tea.", "+It was a sunny day"], text, 1, from: 'en', to: 'ru'))
          .to eql(true)
      expect(text).to eql(["Сэм отправился к своей семье.", "Это был солнечный день", "Он выпил чашку чая."])
    end

    it "Should return false due to absence of '+'" do
      text = ["Сэм отправился к своей семье.", "Он выпил чашку чая."]
      expect(@translator.add_sentence(2,["Sam went to his family.", "He drunk a cup of tea.", "It was a sunny day"], text, 1, from: 'en', to: 'ru'))
          .to eql(false)
      expect(text).to eql(["Сэм отправился к своей семье.", "Он выпил чашку чая."])
    end

    it "Should return false due to wrong index" do
      text = ["Сэм отправился к своей семье.", "Он выпил чашку чая."]
      expect(@translator.add_sentence(9,["Sam went to his family.", "He drunk a cup of tea.", "It was a sunny day"], text, 1, from: 'en', to: 'ru'))
          .to eql(false)
      expect(text).to eql(["Сэм отправился к своей семье.", "Он выпил чашку чая."])
    end

  end


  describe :get_diffs do

      context "There were only deletions" do
        context "There was one deletion in the end" do
          it "Should mark the deleted sentence with '-'" do
            expect(@translator.get_diffs("It was a sunny day. Sam went to his family and then drunk a cup of tea.",
                                         "It was a sunny day."))
                .to eql(:left_diff=>[" It was a sunny day.", "-Sam went to his family and then drunk a cup of tea."],
                        :right_diff=>[" It was a sunny day."])
          end
        end

        context "There was one deletion in the middle" do
          it "Should mark the deleted sentence with '-'" do
            expect(@translator.get_diffs("It was a sunny day. Sam went to his family. He drunk a cup of tea.",
                                         "It was a sunny day. He drunk a cup of tea."))
                .to eql(:left_diff=>[" It was a sunny day.", "-Sam went to his family.", " He drunk a cup of tea."],
                        :right_diff=>[" It was a sunny day.", " He drunk a cup of tea."])
          end
        end

        context "There was one deletion in the beginning" do
          it "Should mark the deleted sentence with '-'" do
            expect(@translator.get_diffs("It was a sunny day. Sam went to his family. He drunk a cup of tea.",
                                         "Sam went to his family. He drunk a cup of tea."))
                .to eql(:left_diff=>["-It was a sunny day.", " Sam went to his family.", " He drunk a cup of tea."],
                        :right_diff=>[" Sam went to his family.", " He drunk a cup of tea."])
          end
        end
      end

      context "There were only additions" do
        context "There was one addition in the end" do
          it "Should mark the added sentence with '+'" do
            expect(@translator.get_diffs("It was a sunny day.",
                                         "It was a sunny day. Sam went to his family and then drunk a cup of tea."))
                .to eql(:left_diff=>[" It was a sunny day."],
                        :right_diff=>[" It was a sunny day.", "+Sam went to his family and then drunk a cup of tea."])
          end
        end

        context "There was one addition in the middle" do
          it "Should mark the added sentence with '+'" do
            expect(@translator.get_diffs("It was a sunny day. He drunk a cup of tea.",
                                         "It was a sunny day. Sam went to his family. He drunk a cup of tea."))
                .to eql(:left_diff=>[" It was a sunny day.", " He drunk a cup of tea."],
                        :right_diff=>[" It was a sunny day.", "+Sam went to his family.", " He drunk a cup of tea."])
          end
        end

        context "There was one deletion in the beginning" do
          it "Should mark the added sentence with '+'" do
            expect(@translator.get_diffs("Sam went to his family. He drunk a cup of tea.",
                                         "It was a sunny day. Sam went to his family. He drunk a cup of tea."))
                .to eql(:left_diff=>[" Sam went to his family.", " He drunk a cup of tea."],
                        :right_diff=>["+It was a sunny day.", " Sam went to his family.", " He drunk a cup of tea."])
          end
        end
      end

      context "There were some changes in sentences" do
        it "Should mark the added sentences with '+' and deleted with '-'" do
          expect(@translator.get_diffs("Sam went to his family. He drunk a cup of tea.",
                                       "Sam went to his family. He drunk a cup of coffee."))
              .to eql(:left_diff=>[" Sam went to his family.", "-He drunk a cup of tea."],
                      :right_diff=>[" Sam went to his family.", "+He drunk a cup of coffee."])
        end
      end
  end

  describe :update_translation do

    context "plain" do

    it "Should translate ru-en whole updated original" do
      expect(@translator.update_translation("", "Квартира с видом на море. 2 комнаты с хорошим ремонтом." ,"" ))
          .to eql("Apartment with sea views. 2 rooms in good repair. ")
    end

    it "Should translate ru-en only last sentence" do
      expect(@translator.update_translation("Квартира с видом на море.", "Квартира с видом на море. 2 комнаты с хорошим ремонтом." ,"Apartment with sea views." ))
          .to eql("Apartment with sea views. 2 rooms in good repair.")
    end


    it "Should translate ru-en and replace last sentence" do
      expect(@translator.update_translation("Квартира с видом на море. 2 комнаты с хорошим ремонтом.", "Квартира с видом на море. 2 комнаты с плохим ремонтом." ,"Apartment with sea views. 2 rooms in good repair." ))
          .to eql("Apartment with sea views. 2 rooms with a bad repair.")
    end

    it "Should translate ru-en and replace middle sentence" do
      expect(@translator.update_translation("Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе.", "Квартира с видом на море. 2 комнаты с отличным ремонтом. Бассейн во дворе." ,"Apartment with sea views. 2 rooms in good repair. The pool in the yard." ))
          .to eql("Apartment with sea views. 2 rooms with excellent repair. The pool in the yard.")
    end

    it "Shouldn't translate anything" do
      expect(@translator.update_translation("Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе.", "Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе." ,"First translation. Second translation. Last translation." ))
          .to eql("First translation. Second translation. Last translation." )
    end

    it "Should translate and remove" do
      expect(@translator.update_translation("Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе.", "Дом в лесу. 4 комнаты и сан-узел." ,"Apartment with sea views. 2 rooms in good repair. The pool in the yard." ))
          .to eql("House in the woods. 4 rooms and WC.")
    end

    it "Should translate sentence without '.'" do
      expect(@translator.update_translation("Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе.", "Дом" ,"Apartment with sea views. 2 rooms in good repair. The pool in the yard." ))
          .to eql("House")
    end

    end

    context "html" do

      it "Should translate and keep boldness " do
        expect(@translator.update_translation("<p><b> Квартира с видом на море. </b>2 комнаты с хорошим ремонтом. Бассейн во дворе. </p>", "<p><b>Дом с видом на море. </b>2 комнаты с хорошим ремонтом. Бассейн во дворе.</p>" ,
                                              "<p><b>Apartment with sea views. </b>2 rooms in good repair. The pool in the yard. </p>", format: "html"))
            .to eql("<p><b>House with sea views. </b>2 rooms in good repair. The pool in the yard. </p>")
      end

      it "Should translate and add boldness " do
        expect(@translator.update_translation("<p>Квартира с видом на море. 2 комнаты с хорошим ремонтом. Бассейн во дворе.</p>", "<p><b>Дом с видом на море. </b>2 комнаты с хорошим ремонтом. Бассейн во дворе.</p>" ,
                                              "<p>Apartment with sea views. 2 rooms in good repair. The pool in the yard.</p>", format: "html" ))
            .to eql("<p><b>House with sea views. </b>2 rooms in good repair. The pool in the yard.</p>")
      end

      it "Should translate, keep italics and add boldness " do
        expect(@translator.update_translation("<i>Квартира с видом на море. 2 комнаты с хорошим ремонтом.</i> Бассейн во дворе.", "<i>Квартира с видом на море. <b>2 комнаты.</b></i> Бассейн во дворе." ,
                                              "<i>Apartment with sea views. 2 rooms in good repair.</i> The pool in the yard.", format: "html"))
            .to eql("<i>Apartment with sea views. <b>2 rooms. </b></i> The pool in the yard.")
      end

      it "Should translate and replace &nbsp! " do
        expect(@translator.update_translation("<i>Квартира&nbsp;с&nbsp;видом на море. 2&nbsp;комнаты с хорошим ремонтом.</i> Бассейн во дворе.", "<i>Квартира&nbsp;с&nbsp;видом на океан. <b>2&nbsp;комнаты.</b></i> Бассейн во дворе." ,
                                              "<i>Apartment with sea views. 2 rooms in good repair.</i> The pool in the yard.", format: "html" ))
            .to eql("<i>Apartment with ocean views. <b>2 rooms. </b></i> The pool in the yard.")
      end
    end
  end
end