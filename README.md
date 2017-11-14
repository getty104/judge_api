# judge_api
sinatraとdockerで作ったジャッジサーバーAPIです。
対応言語はC,C++,Ruby,Python

#初期設定
```
bundle install
docker pull gcc:latest
docker pull ruby:latest
docker pull python:latest
docker pull java:latest
```

#実行方法
```
ruby api.rb
```

#リクエスト例
```
curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"lang":"rb","code":"print gets","input":"test","ans":"test"}' http://localhost:4567/exec
# => {"result":"AC"}
```
