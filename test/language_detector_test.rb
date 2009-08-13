# -*- coding: utf-8 -*-
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/language_detector'

class ProfileTest < Test::Unit::TestCase
  def test_is_puctuation
    p = LanguageDetector::Profile.new("test")
    assert p.is_puctuation?(?,)
    assert p.is_puctuation?(?.)
    assert !p.is_puctuation?(?A)
    assert !p.is_puctuation?(?a)
  end

  def test_tokenize
    p = LanguageDetector::Profile.new("test")
    assert_equal ["this", "is", "A", "test"], p.tokenize("this is ,+_  A \t 123 test")
  end

  def test_count_ngram
    p = LanguageDetector::Profile.new("test")
    assert_equal({"w"=>1, "o"=>1, "r"=>1, "d"=>1, "s"=>1}, p.count_ngram('words', 1, {}))
    assert_equal({"wo"=>1, "or"=>1, "rd"=>1, "ds"=>1, "_w" => 1, "s_" => 1}, p.count_ngram('words', 2, {}))
    assert_equal({"wor"=>1, "ord"=>1, "rds"=>1, "_wo" => 1, "ds_" => 1, "s__" => 1}, p.count_ngram('words', 3, {}))
    assert_equal({"word"=>1, "ords"=>1, "_wor" => 1, "rds_" => 1, "ds__" => 1, "s___" => 1}, p.count_ngram('words', 4, {}))
    assert_equal({"words"=>1, "_word" => 1, "ords_" => 1, "rds__" => 1, "ds___" => 1, "s____" => 1}, p.count_ngram('words', 5, {}))
    assert_equal({}, p.count_ngram('words', 6, {}))
  end

  def test_init_with_string
    p = LanguageDetector::Profile.new("test")
    p.init_with_string("this is ,+_  A \t 123 test")
    assert_equal(
      [["t_", 30], ["st__", 29], ["st", 16], ["hi", 8], ["_tes", 7], ["is__", 6], ["s___", 5], ["s_", 3], ["his_", 11], ["tes", 10], ["t___", 9], ["es", 12], ["_te", 14], ["est_", 13], ["est", 15], ["te", 4], ["his", 17], ["_th", 20], ["s__", 19], ["st_", 18], ["th", 24], ["_thi", 23], ["t__", 22], ["test", 21], ["thi", 28], ["is_", 27], ["this", 26], ["_i", 25], ["is", 2], ["_t", 1]],
      p.ngrams.sort_by { |a,b| a[1] <=> b[1] },
      "This test does not pass in the original repository either: http://github.com/feedbackmine/language_detector"
    )
  end

  def test_init_with_file
    p = LanguageDetector::Profile.new("test")
    p.init_with_file("bg-utf8.txt")
    assert !p.ngrams.empty?
  end

  def test_compute_distance
    p1 = LanguageDetector::Profile.new("test")
    p1.init_with_string("this is ,+_  A \t 123 test")
    p2 = LanguageDetector::Profile.new("test")
    p2.init_with_string("this is ,+_  A \t 123 test")
    assert_equal 0, p1.compute_distance(p2)

    p3 = LanguageDetector::Profile.new("test")
    p3.init_with_string("xxxx")
    assert_equal 24000, p1.compute_distance(p3)
  end
end

class LanguageDetectorTest < Test::Unit::TestCase
  def test_detect
    d = LanguageDetector.new

    assert_equal "es", d.detect("para poner este importante proyecto en práctica")
    assert_equal "en", d.detect("this is a test of the Emergency text categorizing system.")
    assert_equal "fr", d.detect("serait désigné peu après PDG d'Antenne 2 et de FR 3. Pas même lui ! Le")
    assert_equal "it", d.detect("studio dell'uomo interiore? La scienza del cuore umano, che")
    assert_equal "ro", d.detect("taiate pe din doua, in care vezi stralucind brun  sau violet cristalele interioare")
    assert_equal "pl", d.detect("na porozumieniu, na ³±czeniu si³ i ¶rodków. Dlatego szukam ludzi, którzy")
    assert_equal "de", d.detect("sagt Hühsam das war bei Über eine Annonce in einem Frankfurter der Töpfer ein. Anhand von gefundenen gut kennt, hatte ihm die wahren Tatsachen Sechzehn Adorno-Schüler erinnern und daß ein Weiterdenken der Theorie für ihre Festlegung sind drei Jahre Erschütterung Einblick in die Abhängigkeit der Bauarbeiten sei")
    assert_equal "fi", d.detect("koulun arkistoihin pölyttymään, vaan nuoret saavat itse vaikuttaa ajatustensa eteenpäinviemiseen esimerkiksi")
#    assert_equal "sv", d.detect("enligt all sannolikhet för att få ro oavsiktligt intagit en för")
    assert_equal "hu", d.detect("esôzéseket egy kissé túlméretezte, ebbôl kifolyólag a Földet egy hatalmas árvíz mosta el")
    assert_equal "fi", d.detect("koulun arkistoihin pölyttymään, vaan nuoret saavat itse vaikuttaa ajatustensa eteenpäinviemiseen esimerkiksi")
    assert_equal "nl", d.detect("tegen de kabinetsplannen. Een speciaal in het leven geroepen Landelijk")
    assert_equal "da", d.detect("viksomhed, 58 pct. har et arbejde eller er under uddannelse, 76 pct. forsørges ikke længere af Kolding")
    assert_equal "cs", d.detect("datují rokem 1862.  Naprosto zakázán byl v pocitech smutku, beznadìje èi jiné")
    assert_equal "no", d.detect("hånd på den enda hvitere restaurant-duken med en bevegelse så forfinet")
    assert_equal "pt", d.detect("popular. Segundo o seu biógrafo, a Maria Adelaide auxiliava muita gente")
    assert_equal "en", d.detect("TaffyDB finders looking nice so far!")
  end
end
