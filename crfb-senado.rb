=begin
crfb-senado.rb is a Ruby script that downloads constitutional text from the
Federal Senate of Brazil's website and convert them to Markdown format.

crfb-senado.rb was the simple con1988.rb (of same author) under a MIT license

Copyright 2014 Alexandre Magno <alexandre.mbm@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

# sudo apt-get install ruby-nokogiri
# sudo apt-get install ruby-curb

require "curb"
require "nokogiri"

class Getter
  @@targets = {
    :con1988 => "http://www.senado.gov.br/legislacao/const/con1988/CON1988_05.10.1988/art_PATTERN_.shtm",
    :cache => "http://www.senado.gov.br/legislacao/const/con1988/CON1988_PATTERN/index.shtm"
  }
  def initialize()
    @c = Curl::Easy.new    
  end

=begin
<h4>Emendas Constitucionais</h4>
<div style="clear:both; width:100%; padding-top: 10px;">
  <div style="float:left; width:10%; text-align:center;"><a href="../EMC1_31.03.1992/EMC1.shtm">EMC - 1</a></div>
  <div style="float:left; width:15%; text-align:center;">31.03.1992</div>
  <div style="float:left; width:72%; text-align:justify;">Dispõe sobre a remuneração dos Deputados Estaduais e dos Vereadores</div>
</div>
<div style="clear:both; width:100%; padding-top: 10px;">
  <div style="float:left; width:10%; text-align:center;"><a href="../EMC2_25.08.1992/EMC2.shtm">EMC - 2</a></div>
  <div style="float:left; width:15%; text-align:center;">25.08.1992</div>
  <div style="float:left; width:72%; text-align:justify;">Dispõe sobre o plebiscito previsto no art. 2º do Ato das Disposições Constitucionais Transitórias.</div>
</div>
=end

  def cache(date="02.12.2014")
    @url = @@targets[:cache].gsub! "PATTERN", date
    lines = css "div#conteudoConst div[style=\"clear:both; width:100%; padding-top: 10px;\"]"
    url_prefix = "http://www.senado.gov.br/legislacao/const/con1988"
    lines.each do |div|
      children = div.css "div"
      url = children[0].child["href"].gsub /^../ , url_prefix
      name = chomp children[0].text
      date = chomp children[1].text
      desc = chomp children[2].text
      puts "#{name}\n#{date}\n#{desc}\n#{url}"
      puts
    end
  end
  def con1988(article)
    pattern = article.to_s
    @url = @@targets[:con1988].gsub! "PATTERN", pattern
    lines = css "div#conteudoConst p"
    str = ""
    lines.each do |p|
      text = chomp p.text
      case p["class"]
      when "artigo"
        str += text.gsub(/^(Art. [0-9]*º?)\.?/, '**\1**')
        str += "\n"
      when "inciso"        
        str += "* " + text.gsub(/-  /, "– ")
        str += "\n"
      when "alinea"
        str += " * " + text.gsub(")  ", ") ")
        str += "\n"
      when "paragrafo"
        str += text
                .gsub(/^(Parágrafo único.)/, "\n" + '**\1**')
                .gsub(/^(§ [0-9]*º)/, '* **\1**')
        str += "\n"
      end
    end
    str
  end
  private
  def css(css)  # TODO issue #4 "Tratar exceção de falta de Internet"
    @c.url = @url
    @c.perform
    page = Nokogiri::HTML @c.body_str
    page.css css
  end
  def chomp(str)
    nbsp = Nokogiri::HTML("&nbsp;").text
    str
      .gsub(nbsp, " ")
      .chomp
      .gsub(/\r/, "")
      .gsub(/^[ \t\n]*/, "")
      .gsub(/[ \t\n]*$/, "")
  end
end

require 'optparse'
require 'ostruct'

options = OpenStruct.new
options.text = nil
options.article = nil
options.link = false
options.notes = false
options.cache = false
options.amendment = nil

=begin
$ crfb-senado.rb -t 1988 -a 5          # salva o artigo 5º do texto de 1988
$ crfb-senado.rb -t 2014 -a 5          # salva o artigo 5º do texto de 2014
$ crfb-senado.rb -t 2014 -a 5 --notes  # salva o artigo 5º do texto de 2014 com notas de rodapé
$ crfb-senado.rb --cache               # faz um cache que possibilita o comando -e
$ crfb-senado.rb -e 25                 # salva arquivo da emenda 25
$ crfb-senado.rb -e 25 --link          # atualiza artigos para ter ligações internas
=end

optparse = OptionParser.new do |opts|
  opts.banner  = "Usage: #{opts.program_name} INTEGER"
  opts.separator "       #{opts.program_name} -t INTEGER -a INTEGER [--notes]"
  opts.separator "       #{opts.program_name} -e INTEGER [--link]"
  opts.separator "       #{opts.program_name} --cache"
  opts.separator ""
  opts.separator "   If using the unique parameter, it downloads article of 1988."
  opts.separator ""
  opts.on("-t INTEGER", Integer, "Year of the text: 1988 or 2014") do |year|
    options.text = year
  end
  opts.on("-a INTEGER", Integer, "Number of the article") do |article|
    options.article = article
  end
  opts.on("-e INTEGER", Integer, "Number of the amendment") do |e|
    options.amendment = e
  end
  opts.on("--link", "To link internally in the articles") do
    options.link = true
  end
  opts.on("--notes", "To create with footnotes") do
    options.notes = true
  end
  opts.on("--cache", "To prepare cache to commands \"-e\"") do
    options.cache = true
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

begin
  optparse.parse!
rescue OptionParser::InvalidOption => msg
  puts msg
  exit(-2)
rescue OptionParser::InvalidArgument => msg
  puts msg
  exit(-2)
rescue OptionParser::MissingArgument => msg
  puts msg
  exit(-2)
end

if ARGV.empty?
  if options.cache
    if options.text or options.article or options.notes or options.amendment or options.link
      puts "error: \"--cache\" was used together with others paramters"
      exit(-1)
    else
      # crfb-senado.rb --cache
      puts "cache is a functionality not implemented"  # TODO
      Getter::new.cache
      exit
    end
  elsif options.amendment
    if options.text or options.article or options.cache or options.notes
      puts "error: \"-e INTEGER\" only can to be combined with \"--link\""
      exit(-1)
    elsif options.link
      # crfb-senado.rb -e 25 --link
      puts "amendment+link is a functionality not implemented"  # TODO
      exit
    else
      # crfb-senado.rb -e 25
      puts "amendment is a functionality not implemented"  # TODO
      exit
    end
  elsif (options.text and !options.article) or (options.article and !options.text)
      puts "error: \"-t INTEGER\" or \"-a INTEGER\" is missing"
      exit(-1)
  elsif options.text and options.article
    if options.amendment or options.cache or options.link
      puts "error: \"-t INTEGER -a INTEGER\" only can to be combined with \"--notes\""
      exit(-1)
    elsif options.notes
      # crfb-senado.rb -t 1988 -a 5 --notes
      # crfb-senado.rb -t 2014 -a 5 --notes
      puts "(text/article)+notes is a functionality not implemented"  # TODO
      exit
    else
      # crfb-senado.rb -t 1988 -a 5
      # crfb-senado.rb -t 2014 -a 5
      puts "text/article is a functionality not implemented"  # TODO
      exit
    end
  else
    puts optparse
    exit(-1)
  end
end

begin
  article = Integer(ARGV.pop)
  raise "Need to specify a article to process" unless article  # called never
  collector = Getter::new
  str = collector.con1988(article)
  File.write('art_' + article.to_s + '.md', str)
rescue ArgumentError => msg
  puts "Unique parameter needs to be an integer"
end
