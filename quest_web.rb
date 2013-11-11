require 'sinatra'
require 'sinatra/json'
require 'json'
require 'slim'
require 'net/http'
require 'uri'

DATA_FILE = File.expand_path('../ruby.txt', __FILE__)
BASE_URL = 'http://localhost:9292'
uri = URI.parse(BASE_URL)
HTTP = Net::HTTP.new(uri.host, uri.port)

def get(path)
  get_response(Net::HTTP::Get.new(path))
end

def post(path, data)
  request = Net::HTTP::Post.new(path)
  request.body = JSON.dump(data)
  request["Content-Type"] = "application/json"
  get_response(request)
end

def get_response(request)
  response = HTTP.request(request)
  if response.code == "200"
    return JSON.parse(response.body)
  else
    raise "Exit code #{response.code}"
  end
end

def parse_data(data)
  data.split(/^=$/).map do |question_data|
    parse_question(question_data)
  end
end

def parse_question(question_data)
  question_text, *answers_data = question_data.split(/^$/).map(&:strip).reject(&:empty?)
  { :question => question_text,
    :answers  => parse_answers(answers_data)    }
end

def parse_answers(answers_data)
  answers_data.map do |answer_data|
    { :answer => answer_data.sub(/^\* */,''),
      :correct => answer_data.start_with?('*') }
  end
end

before '/' do
  right_answer = false
  if params.has_key?('answers')
    result = post('/answer', {'id' => Integer(params['id']),
                  'answers' => params['answers']})
    right_answer = result['correct'] 
  end
  if right_answer
    @correct = "Congratulations!"
    question = get('/question')
  elsif !params.has_key?('answers')
    question = get('/question')
  else
    @correct = "Sorry! Try again."
    question = post('/question-by-id',{'id' => Integer(params['id'])})
  end
 
  @question_text = question['question'] 
  @id = question['id']
  @answers = question['answers']
end

get '/' do
  slim :index
end

post '/' do
  slim :index
end

QUESTIONS = parse_data(File.read(DATA_FILE))
get '/question' do
  id = rand(QUESTIONS.size)
  question = QUESTIONS[id]
  response = {}
  response[:id] = id
  response[:question] = question[:question]
  response[:answers] = question[:answers].map do |answer|
  answer[:answer]
  end
  json(response)
end

post '/question-by-id' do
  data = JSON.parse(request.body.read)
  id = data['id']
  question = QUESTIONS[id]
  response = {}
  response[:id] = id
  response[:question] = question[:question]
  response[:answers] = question[:answers].map do |answer|
  answer[:answer]
  end
  json(response)
end

post '/answer' do
  data = JSON.parse(request.body.read)
  question = QUESTIONS[data['id']]
  correct_answers = question[:answers].select do |answer|
    answer[:correct]
  end
  correct_answers = correct_answers.map { |a| a[:answer] }
  correct = correct_answers.sort == data['answers'].sort
  json(:correct => correct)
end
