---
layout: single
title: "CoreCLR Review"
date: 2016-01-06T17:36:55+02:00
modified:
categories:
excerpt:
tags: []
comments: true
share: true
---

Tests:
https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/tests/src/JIT/jit64/opt/lim/lim_002.cs#L69

https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/tests/src/JIT/jit64/gc/regress/vswhidbey/339415.cs#L17-L78


GC code
One file
70K lines of code
Why?? Easy to search!
https://twitter.com/xjoeduffyx/status/674603291968311297

My machine
https://github.com/dotnet/coreclr/blob/release/1.0.0-rc1/src/vm/comsynchronizable.cpp#L2008


Magic!!
Null pointer:
https://alexandrnikitin.github.io/blog/access-a-null-pointer-without-exception/
