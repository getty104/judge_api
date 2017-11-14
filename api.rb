require 'sinatra'
require 'docker'

post '/exec' do
  body = JSON.parse(request.body.read)
  if body["lang"] == nil || body["code"] == nil  || body["input"] == nil || body["ans"] == nil
    status 400
  else
    #return {result: judge(body["lang"], body["code"], body["input"], body["ans"])}.to_json
    return {result: judge('java', <<-EOS, body["input"], body["ans"])}.to_json
    public class Main {
      public static void main(String[] args) {
        System.out.print("test");
      }
    }
    EOS
  end
end

def judge lang, code, input, ans
  case lang
  when 'c'
    file_name = "main.c"
    container = create_container 'gcc:latest', file_name, code, input
    ce = container.exec(["sh", "-c", "timeout -s 9 5 gcc #{file_name}"]).last == 0
    exec_cmd = './a.out'
  when 'cpp'
    file_name = "main.cpp"
    container = create_container 'gcc:latest', file_name, code, input
    ce = container.exec(["sh", "-c", "timeout -s 9 5 g++ #{file_name}"]).last == 0
    exec_cmd = './a.out'
  when 'py'
    file_name = "main.py"
    container = create_container 'python:latest', file_name, code, input
    exec_cmd = "python #{file_name}"
  when 'rb'
    file_name = "main.rb"
    container = create_container 'ruby:latest', file_name, code, input
    exec_cmd = "ruby #{file_name}"
  when 'java'
    file_name = "Main.java"
    class_name = "Main"
    container = create_container 'java:latest', file_name, code, input
    ce = container.exec(["sh", "-c", "timeout -s 9 5 javac #{file_name}"])
    exec_cmd = "java #{class_name}"
  end

  return 'CE' unless ce
  sleep(0.005)
  result = container.exec(["sh", "-c", "timeout -s 9 2 #{exec_cmd} < input.txt"])
  container.delete(force: true)
  case result.last
  when 1
    return 'RE'
  when 0
    return result[0][0] == ans ? 'AC' : 'WA'
  else
    return 'RE'
  end
end

def create_container image_name, file_name, code, input
  memory = 128
  options = {
    'Image' => image_name,
    'Tty' => true,
    'HostConfig' => {
      'Memory' => memory * 1024 * 1024,
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
