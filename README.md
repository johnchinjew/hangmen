# Hangmen

## TODO

- Debug server and implement client
- Make use of long-polling
- Introduce typed Ids for client
- Sanitize before sending session state in BE

## Build and run

```
npm start
```

## curl API commands

### new-session

```
curl -d "" http://localhost:3000/new-session
```


### join-session

```
curl -d '{"sid":"5646a669-7092-43be-a6b6-b818ff7b5ce6", "name":"joji"}' -H "Content-Type: application/json" -X POST http://localhost:3000/join-session
```

### set-word

```
curl -d '{"sid":"5646a669-7092-43be-a6b6-b818ff7b5ce6", "pid":"8d6c276f-fc54-4c60-9617-9d8c78a91ae8", "word":"hey"}' -H "Content-Type: application/json" -X POST http://localhost:3000/set-word
```
