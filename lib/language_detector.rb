require 'yaml'
require 'jcode' if RUBY_VERSION < '1.9'
$KCODE = 'u' if RUBY_VERSION < '1.9'

class LanguageDetector
  def detect text
    @profiles ||= load_model

    p = LanguageDetector::Profile.new("")
    p.init_with_string text
    best_profile = nil
    best_distance = nil
    @profiles.each {|profile|
      distance = profile.compute_distance(p)

      if !best_distance || distance < best_distance
        best_distance = distance
        best_profile = profile
      end
    }
    return best_profile.name
  end

  def self.train

    # For a full list of ISO 639 language tags visit:

    # http:#www.loc.gov/standards/iso639-2/englangn.html

    #LARGE profiles follow:

    #NOTE: These profiles taken from the "World War II" node on wikipedia
    #with the 'lang' and ?action=raw URI which results in a UTF8 encoded
    #file.  If we need to get more profile data for a language this is
    #always a good source of data.
    #
    # http:#en.wikipedia.org/wiki/World_War_II

    training_data = [
      # af (afrikaans)
      [ "ar", "ar-utf8.txt", "utf8", "arabic" ],
      [ "bg", "bg-utf8.txt", "utf8", "bulgarian" ],
      # bs (bosnian )
      # ca (catalan)
      [ "cs", "cs-utf8.txt", "utf8", "czech" ],
      # cy (welsh)
      [ "da", "da-iso-8859-1.txt", "iso-8859-1", "danish" ],
      [ "de", "de-utf8.txt", "utf8", "german" ],
      [ "el", "el-utf8.txt", "utf8", "greek" ],
      [ "en", "en-iso-8859-1.txt", "iso-8859-1", "english" ],
      [ "et", "et-utf8.txt", "utf8", "estonian" ],
      [ "es", "es-utf8.txt", "utf8", "spanish" ],
      [ "fa", "fa-utf8.txt", "utf8", "farsi" ],
      [ "fi", "fi-utf8.txt", "utf8", "finnish" ],
      [ "fr", "fr-utf8.txt", "utf8", "french" ],
      [ "fy", "fy-utf8.txt", "utf8", "frisian" ],
      [ "ga", "ga-utf8.txt", "utf8", "irish" ],
      #gd (gaelic)
      #haw (hawaiian)
      [ "he", "he-utf8.txt", "utf8", "hebrew" ],
      [ "hi", "hi-utf8.txt", "utf8", "hindi" ],
      [ "hr", "hr-utf8.txt", "utf8", "croatian" ],
      #id (indonesian)
      [ "io", "io-utf8.txt", "utf8", "ido" ],
      [ "is", "is-utf8.txt", "utf8", "icelandic" ],
      [ "it", "it-utf8.txt", "utf8", "italian" ],
      [ "ja", "ja-utf8.txt", "utf8", "japanese" ],
      [ "ko", "ko-utf8.txt", "utf8", "korean" ],
      #ku (kurdish)
      #la ?
      #lb ?
      #lt (lithuanian)
      #lv (latvian)
      [ "hu", "hu-utf8.txt", "utf8", "hungarian" ],
      #mk (macedonian)
      #ms (malay)
      #my (burmese)
      [ "nl", "nl-iso-8859-1.txt", "iso-8859-1", "dutch" ],
      [ "no", "no-utf8.txt", "utf8", "norwegian" ],
      [ "pl", "pl-utf8.txt", "utf8", "polish" ],
      [ "pt", "pt-utf8.txt", "utf8", "portuguese" ],
      [ "ro", "ro-utf8.txt", "utf8", "romanian" ],
      [ "ru", "ru-utf8.txt", "utf8", "russian" ],
      [ "sl", "sl-utf8.txt", "utf8", "slovenian" ],
      #sr (serbian)
      [ "sv", "sv-iso-8859-1.txt", "iso-8859-1", "swedish" ],
      #[ "sv", "sv-utf8.txt", "utf8", "swedish" ],
      [ "th", "th-utf8.txt", "utf8", "thai" ],
      #tl (tagalog)
      #ty (tahitian)
      [ "uk", "uk-utf8.txt", "utf8", "ukraninan" ],
      [ "vi", "vi-utf8.txt", "utf8", "vietnamese" ],
      #wa (walloon)
      #yi (yidisih)
      [ "zh", "zh-utf8.txt", "utf8", "chinese" ]
    ]

    profiles = []
    training_data.each {|data|
      p = LanguageDetector::Profile.new data[0]
      p.init_with_file data[1]
      profiles << p
    }
    puts 'saving model...'
    filename = File.expand_path(File.join(File.dirname(__FILE__), "model.yml"))
    File.open(filename, 'w') {|f|
      YAML.dump(profiles, f)
    }
  end

  def load_model
    filename = File.expand_path(File.join(File.dirname(__FILE__), "model.yml"))
    @profiles = YAML.load_file(filename)
  end

  class LanguageDetector::Profile

    PUNCTUATIONS = [?\n, ?\r, ?\t, ?\s, ?!, ?", ?#, ?$, ?%, ?&, ?', ?(, ?), ?*, ?+, ?,, ?-, ?., ?/,
    ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9,
    ?:, ?;, ?<, ?=, ?>, ??, ?@, ?[, ?\\, ?], ?^, ?_, ?`, ?{, ?|, ?}, ?~]

    LIMIT = 2000

    def compute_distance other_profile
      distance = 0
      other_profile.ngrams.each {|k, v|
        n = @ngrams[k]
        if n
          distance += (v - n).abs
        else
          distance += LanguageDetector::Profile::LIMIT
        end
      }
      return distance
    end

    attr_reader :ngrams, :name

    def initialize(name)
      @name = name
      @puctuations = {}
      PUNCTUATIONS.each {|p| @puctuations[p] = 1}
      @ngrams = {}
    end

    def init_with_file filename
      ngram_count = {}

      path = File.expand_path(File.join(File.dirname(__FILE__), "training_data/" + filename))
      puts "training with " + path
      File.open(path).each_line{ |line|
        _init_with_string line, ngram_count
      }

      a = ngram_count.sort {|a,b| b[1] <=> a[1]}
      i = 1
      a.each {|t|
        @ngrams[t[0]] = i
        i += 1
        break if i > LIMIT
      }
    end

    def init_with_string str
      ngram_count = {}

      _init_with_string str, ngram_count

      a = ngram_count.sort {|a,b| b[1] <=> a[1]}
      i = 1
      a.each {|t|
        @ngrams[t[0]] = i
        i += 1
        break if i > LIMIT
      }
    end

    def _init_with_string str, ngram_count
      tokens = tokenize(str)
      tokens.each {|token|
        count_ngram token, 2, ngram_count
        count_ngram token, 3, ngram_count
        count_ngram token, 4, ngram_count
        count_ngram token, 5, ngram_count
      }
    end

    def tokenize str
      tokens = []
      s = ''
      str.each_byte {|b|
        if is_puctuation?(b)
          tokens << s unless s.empty?
          s = ''
        else
          s << b
        end
      }
      tokens << s unless s.empty?
      return tokens
    end

    def is_puctuation? b
      @puctuations[b]
    end

    def count_ngram token, n, counts
      if RUBY_VERSION < '1.9'
        token = "_#{token}#{'_' * (n-1)}" if n > 1 && token.jlength >= n
      else
        token = "_#{token}#{'_' * (n-1)}" if n > 1 && token.length >= n
      end
      i = 0
      while i + n <= token.length
        s = ''
        j = 0
        while j < n
          s << token[i+j]
          j += 1
        end
        if counts[s]
          counts[s] = counts[s] + 1
        else
          counts[s] = 1
        end
        i += 1
      end

      return counts
    end

  end

end

if $0 == __FILE__
  if ARGV.length == 1 && 'train' == ARGV[0]
    LanguageDetector.train
  else
    d = LanguageDetector.new
    p d.detect("what language is it is?")
  end
end

