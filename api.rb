require 'sinatra'
require 'docker'

post '/exec' do
  body = JSON.parse(request.body.read)
  if body["lang"] == nil || body["code"] == nil  || body["input"] == nil || body["ans"] == nil
    status 400
  else
    return {result: judge(body["lang"], body["code"], body["input"], body["ans"])}.to_json
  end
end

def judge lang, code, input, ans
  case lang
  when 'c'
    file_name = "main.c"
    container = create_container('gcc:latest', file_name, code, input)
    ce = container.exec(["timeout", "10", "bash", "-c", "gcc #{file_name}"]).last != 0
    exec_cmd = './a.out'
  when 'cpp'
    file_name = "main.cpp"
    container = create_container('gcc:latest', file_name, code, input)
    ce = container.exec(["timeout", "10", "bash", "-c", "g++ #{file_name}"]).last != 0
    exec_cmd = './a.out'
  when 'py'
    file_name = "main.py"
    container = create_container('python:latest', file_name, code, input)
    exec_cmd = "python #{file_name}"
  when 'rb'
    file_name = "main.rb"
    container = create_container('ruby:latest', file_name, code, input)
    exec_cmd = "ruby #{file_name}"
  end

  return 'CE' if ce
  sleep(0.005)
  result = container.exec(["timeout", "30", "bash", "-c", "time #{exec_cmd} < input.txt"])
  container.delete(force: true)

  case result.last
  when 0
    time = result[1][0].split[3].split("m")[1].to_f
    case
    when (result[0][0] == ans && time <= 2.0) then return 'AC'
    when (result[0][0] == ans && time >  2.0) then return 'TLE'
    when (result[0][0] != ans)                then return 'WA'
    end
  else
    return 'RE'
  end
end

def create_container image_name, file_name, code, input
  memory = 500 * 1024 * 1024
  options = {
    'Image' => image_name,
    'Tty' => true,
    'HostConfig' => {
      'Memory' => memory,
      'PidsLimit' => 10
    },
    'WorkingDir' => '/tmp'
  }
  container = Docker::Container.create(options)
  container.start
  container.store_file("/tmp/#{file_name}", code)
  container.store_file("/tmp/input.txt", input)
  return container
end
