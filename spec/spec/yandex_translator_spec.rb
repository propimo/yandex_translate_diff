require 'spec_helper'
require '../../yandex_translate_diff/lib/yandex_translate_diff/yandex_translator'

describe Translator::YandexTranslator do

  before { @translator = Translator::YandexTranslator.new }

  #add FORMAT HTML

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

=begin
  describe :update_translation do
    it "Should translate en-ru whole updated original" do
      expect(@translator.update_translation("", "" ,"" ))
          .to eql("")
    end
  end
=end

end