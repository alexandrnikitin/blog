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

I respect and admire him a lot, he has huge experience in testing and does a lot to popularize testing in development culture.
But I cannot agree with that statement.

Thinking about regression during development is against our nature. Developers don't think about what would happen with their software if... They think about the code they write at that moment: how to implement the feature or how not to break everything with their changes.

The single purpose of having tests is to have **confidence**. The confidence that the code you just wrote works. The confidence that you followed business requirements.

There's only one question you should answer writing tests: **"Do you trust the code?"** Are you confident enough that your software works to release it?

The level of confidence depends. Solely on you and your team. This is what reviews are good for: to come to one opinion and find the level of confidence that's good enough to meet your requirements.

>Automated tests can only demonstrate that the software works correctly if the tests are written correctly

All software have bugs. That's reality. If it's not in your code then it's in libraries you use, frameworks, runtimes or databases. They are there. You cannot change that. We just cannot code it once and get it right on the first time. This is **even more actual** for tests. We, developers, pay less attention to tests than to code. I don't know if it is even possible to change this attitude. TDD? But it doesn't work. Probably, only [Volkswagen managed to get TDD work][Volkswagen].

Even if a test isn't correct then it's a bug. And that's absolutely **normal!** That's how software is made. Yes, there're tools that can help you a bit such as test coverage tools and static and runtime analysers. But don't even think about tests for tests.

>Assuming that all automated tests are correct, then yes: automated tests also demonstrate that the software works, but it's still regression testing. The tests were written to demonstrate that the software worked correctly once. Running the tests repeatedly only demonstrates that it still works correctly.

I can hardly remember cases when tests helped to avoid or find regression issues. Because when you change your code you will change the tests too.

TBA

### About tests

There are many type of tests that varies by purpose, intention and scale:

1. Unit tests - These verify units, the smallest piece of a software. A class? I prefer to treat a method as a unit.

2. Component tests - These limit the scope to a component (module) and verify the business logic and how your units interacts with each other. Tests are performed through the public API.

3. Integration tests verify interactions between components to detect interface defects. The SUT could be an HTTP client gateway to an external service or an ORM layer to an external datasource.

4. End-to-end tests verify that a system meets external and internal requirements. The SUT is a service, API or UI.

5. Multi End-to-end tests becomes more actual with rise of microservices. They verify that whole infrastructure of services works as expected.

6. Performance tests verify that you meet the performance requirements and test individual pieces of code. The SUT can be anything: a service, a module or just a method.

Regression tests? 

### The Test Pyramid:

[Martin Fowler writes about that:][Fowler]
>The test pyramid is a concept developed by Mike Cohn, described in his book Succeeding with Agile. Its essential point is that you should have many more low-level unit tests than high level end-to-end tests running through a GUI.

But there is no such thing as "Test Pyramid", there are only different types of test. It just happened that average project has such distribution across types of tests, only because it's easier to write and get feedback from a unit than any other type of tests. You shouldn't keep that pyramid in mind, you should not "have many more low-level unit tests than high level end-to-end tests running through a GUI." If it's easier for you to write and maintain (or it's enough to have only) Component or End-to-end tests then let it be like that.


### Examples

Multithreaded copy pasted example. And it's good. It helped to repro the issue that reproduced only in prod in rare cases. But changing design just to suit that tests is ridiculous.

Complex tests- i would write the r adjust them, probably refactor. Right now I'll just throw them away. I don't want to waste my time.
Integration tests, yes you test third-party code. Do you believe in backwards compatibility, I don't trust you,
versioning is better, you support and follow semver I almost love you.

Integration tests example from corefx.



So, coming back to the raised question:
> FAQ: How should you unit test internals?

A: It depends. Solely on you and your team. This is what reviews are good for: to come to one opinion and find the level of confidence that's good enough for your requirements.

You absolutely good not to write any test. I'm serious. If it won't increase confidence for you or the team then don't do it. Don't waste your time, don't waste your colleagues' time. Don't do it. Test for the sake of test - they cost.

I'm good to tests internals, even I'm good to test privates if it's need to be private and you need to test that. But it definitely should be an exception.


  [MarkSeemannPost]: http://blog.ploeh.dk/2015/09/22/unit-testing-internals/
  [Volkswagen]: https://en.wikipedia.org/wiki/Volkswagen_emissions_scandal
  [Fowler]: http://martinfowler.com/bliki/TestPyramid.html