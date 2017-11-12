# judge_api
sinatraとdockerで作ったジャッジサーバーAPIです。

#初期設定
```
bundle install
```

#実行方法
```
ruby api.rb
```

#リクエスト例
```
curl -v -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"lang":"rb","code":"print \"test\"","input":"","ans":"test"}' http://localhost:4567/exec
# => {"result":"AC"}
```
