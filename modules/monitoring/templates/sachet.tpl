providers:
  telegram:
    token: "${telegram_token}"

receivers:
  - name: 'fanya-telegram'
    provider: 'telegram'
    to:
      - '-463382846'
