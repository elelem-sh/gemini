# elelem-gemini

A [Google Gemini](https://aistudio.google.com/apikey) provider plugin for [elelem](https://elelem.sh).
It talks to Google Gemini's OpenAI-compatible Chat Completions API
through [elelem-openai](https://github.com/elelem-sh/openai).

## Install

```sh
gem install elelem-gemini
```

## Use

```sh
export GEMINI_API_KEY=...
elelem -p gemini --model MODEL
```

* `GEMINI_API_KEY` (required): get one at https://aistudio.google.com/apikey
* `GEMINI_MODEL`: the model, when `--model` is not given
* `GEMINI_BASE_URL`: overrides `https://generativelanguage.googleapis.com/v1beta/openai`

There is no default model, since free model lists change often. With
no model set, elelem stops and names `GEMINI_MODEL`. A variable that is
set but empty counts as unset.

Free tier limits are on Google Gemini's own page: https://ai.google.dev/gemini-api/docs/rate-limits

## Development

```sh
bin/setup
bin/test
bin/lint
```

## License

MIT. See LICENSE.txt.
