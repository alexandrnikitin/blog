---
layout: post
title: A single purpose of automated testing
date: 2015-10-20
modified: 2015-10-20
excerpt: About tests
tags: [Testing]
comments: true
share: true
---


This post is written in reply to [the recent "Unit testing internals"][MarkSeemannPost] post by Mark Seemann and was, basically, triggered by the statement:

>Automated testing (as opposed to manual testing) only serves a single purpose: it prevents regressions.

I respect him and admire, he has huge experience in testing and does a lot to popularize testing in development culture.
But I cannot agree with that statement.

Thinking about regression during development is against nature. Developers don't think about what would happen with their code if... They think about the code they write at that moment: how to implement the feature or how not to break everything with their changes.

The single purpose of having tests is to have **confidence**. The confidence that the code you just wrote works. The confidence that you followed business requirements.

We just cannot code it once and get it right on the first time. This is **even more actual** for tests. We developers pay less attention to tests than to code. Probably it isn't possible to change this attitude. TDD? But it doesn't work. Probably only [Volkswagen managed to get TDD work][Volkswagen].

Experience about finding bugs because of regression. When you change your code you will change the tests too.

Should you test internals .
It depends and solely on you and your team.that's why review s are good. To come to one opinion and find that level of confidence that's good enough.

You absolutely good to not write any test. I'm serious. If ... Don't waste your time, don't waste somebody elses time. Don't do it. Test for the sake of test.
All software have bugs. That's reality. If its not in your code its in libraries you use, frameworks, runtimes, databases. You hardly can change that. And tests won't really help you. Are you confident enough that your software works to release it?

Automated tests can only demonstrate that the software works correctly if the tests are written correctly

Even if the test isn't correct then it's a bug. And it's absolutely normal. It's how software is made. Tests for tests.
Coverage. Analysers.



There are many type of tests, varies by purpose and intention
Unit tests test units, the smallest piece of your software. Class method?
Again, to increase confidence.
Multithreaded copy pasted example. And it's good. It helped to repro the issue that reproduced only in prod in rare cases. But changing design just to suit that tests is ridiculous.
Complex tests- i would write the r adjust them, probably refactor. Right now I'll just throw them away. I don't want to waste my time.
Integration tests, yes you test third-party code. Do you believe in backwards compatibility, I don't trust you,
versioning is better, you support and follow semver I almost love you.

Regression tests, I prefer field reports but unit still needs to be added.

Microservices arise, multi e2e tests that affect more than one service.

I'm good to tests internals, even I'm good to test privates if it's need to be private and you need that test. But it definitely should be an exception.

Test pyramids. There is no such.
That could be true for huge code bases with all layers, infrastructure, integration, service, business, ui.


  [MarkSeemannPost]: http://blog.ploeh.dk/2015/09/22/unit-testing-internals/
  [Volkswagen]: https://en.wikipedia.org/wiki/Volkswagen_emissions_scandal
