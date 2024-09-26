---
title: How to add custom emoji to your Hugo site
date: "2024-09-26T19:24:09+07:00"
draft: false
showComments: true
description: "Add custom emoji to your Hugo site, support 
gif, png, jpg, webp and svg"
tags:
- hugo
- random
---

{{< sticker "crying-fading" >}}
{{< sticker "gopher-east-lao" >}}

Emojis are an effective way to express your emotion through line of text,
giving readers insight into your personality and sense of humor 

The standard way to use emoji on the internet: 
[unicode emoji wikipedia](https://en.wikipedia.org/wiki/Template:Unicode_chart_single_emojis)

But sometime that's not enough and you may want to add more, for example:
- A funnier emoji packs (twitter emojis, facebook emojis...), or even gif
  emoji.
- Quickly grab a logo, icon and embed it to the text.

## Hugo's default emoji

[Hugo](https://gohugo.io/) does support parsing emoji using
[shortcode](https://gohugo.io/quick-reference/emojis/)

:emoji-name: -> 😄

I believe it's enabled by default. If not, here's how you 
can enable it:
`./hugo.yaml` or `./config/_default/config.yaml`
```yaml
enableEmoji: true
```

## Add your custom emoji with hugo-vmoji

I made a little [Hugo module](https://github.com/remvn/hugo-vmoji) to address my
custom emoji problem, simply put images in a directory, run a cli command and
you are done! 

Installation process is documented
[here](https://github.com/remvn/hugo-vmoji?tab=readme-ov-file#installation)
, it's quite simple.

{{< sticker "this-is-fine" >}}
