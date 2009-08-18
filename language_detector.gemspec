Gem::Specification.new do |s|
  s.name = %q{language_detector}
  s.version = "0.1.2"

  s.authors = ["feedbackmine"]
  s.description = %q{n-gram based language detector, written in ruby}
  s.email = %q{feedbackmine@feedbackmine.com}
  s.files = ["README", 
            "Manifest.txt",
            "lib/language_detector.rb",  
            "lib/model.yml",
            "test/language_detector_test.rb"]
  #s.has_rdoc = true
  s.homepage = %q{http://www.tweetjobsearch.com}
  #s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.summary = %q{n-gram based language detector, written in ruby}
end
