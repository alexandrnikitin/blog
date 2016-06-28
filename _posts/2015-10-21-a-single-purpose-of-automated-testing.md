---
layout: single
title: A single purpose of automated testing
date: 2015-10-21
modified: 2015-10-21
excerpt: About different types of tests, their purpose and how you should test internals.
categories: [Testing]
tags: [Testing]
comments: true
share: true
---


This post is written in reply to [the recent "Unit testing internals"][mark-seemann-post] post by Mark Seemann and was, basically, triggered by the statement:

>Automated testing (as opposed to manual testing) only serves a single purpose: it prevents regressions.

I respect and admire him a lot, he has extensive experience in testing and does a lot to popularize testing in development culture.
But I cannot agree with that statement.

Thinking about regression during development is against our nature. Developers don't think about what would happen with their software if... They think about the code they write at that moment: how to implement the feature or how not to break everything with their changes.

### Confidence

The single purpose of having tests is to have **confidence**. The confidence that the code you just wrote works. The confidence that you followed business requirements.

There's only one question you should answer while writing tests: **"Do you trust the code?"** Are you confident enough that your software works to release it?

The level of confidence depends on you, your team and requirements. This is what reviews are good for: to come to one opinion and find the level of confidence that's good enough to meet your requirements.

>Automated tests can only demonstrate that the software works correctly if the tests are written correctly

All software have bugs. That's reality. If they're not in your code then they're in libraries you use, frameworks, runtimes, databases or infrastructure. They are there. You cannot change that. We just cannot code it once and get it right on the first time. This is **even more actual** for tests. We, developers, pay less attention to tests than to code. I don't know if it is even possible to change this attitude. TDD? But it doesn't work. Probably, only [Volkswagen managed to get TDD work][tdd-volkswagen] :laughing:.

Even if a test isn't correct then it's a bug. And that's absolutely **normal!** That's how software is made. Yes, there're tools that can help you a bit, such as test coverage tools and static and runtime analyzers. But don't even think about tests for tests.

>Assuming that all automated tests are correct, then yes: automated tests also demonstrate that the software works, but it's still regression testing. The tests were written to demonstrate that the software worked correctly once. Running the tests repeatedly only demonstrates that it still works correctly.

I can hardly recall cases when tests helped to avoid or find regression issues. Because when you change your code you will change the tests too. But I can remember a lot of cases when implemented feature didn't work as expected.

### About tests

There are many type of tests that varies by purpose, intention and scale:

1. Unit tests - These verify units, the smallest piece of software. A class? I prefer to treat a method/function as a unit. This leads to more loosely coupled code. The purpose is to test a piece of code, any piece that, in your opinion, needs to be tested.

2. Component tests - These limit the scope to a component (module) and verify the business logic and how units interacts with each other. Tests performed through the public API of a component. The purpose is to test the logic the component is responsible for.

3. Integration tests verify interactions between components to detect interface defects. The SUT could be an HTTP client gateway to an external service or an ORM layer to an external datasource.

4. End-to-end tests verify that a system meets external and internal requirements. The SUT is a whole system, service, API or UI, the tests performed from a client perspective.

6. Performance tests verify that you meet the performance requirements and test individual pieces of code. The SUT can be anything: a service, a module or just a method.

And all those tests serve a single purpose: **gain confidence** that you wrote right software and did it right.

### The Test Pyramid:

[Martin Fowler writes about that:][martin-fowler-test-pyramid]
>The test pyramid is a concept developed by Mike Cohn, described in his book Succeeding with Agile. Its essential point is that you should have many more low-level unit tests than high level end-to-end tests running through a GUI.

But there is no such thing as "Test Pyramid", there are only different types of test. It just happened that average project has such distribution across types of tests, only because it's easier to write and get feedback from a unit test than any other type of tests. You shouldn't keep that pyramid in mind, you should not "have many more low-level unit tests than high level end-to-end tests running through a GUI." If it's easier for you to write and maintain (or enough to have only) Component or End-to-end tests then let it be like that.

### Some not related examples

##### Multithreaded issue
Once I encountered a concurrency problem that occasionally appeared in production. I couldn't reproduce it through the public interface. What I did is narrowed down the scope to the involved classes, "copypased" their code to a unit test, exposed thread synchronization mechanisms through the public interface and wrote a test using them. I find that approach absolutely right, it helped to reproduce and fix the problem. Yes, it's a "copypaste", the test verifies not production code but refactoring and changing the design just because of one problem is absurd, fragile and costs.

##### A bug in .NET internals
Some time ago I encountered [an issue in .NET Framework internals][corefx-issue]. It was clearly a bug and wasn't revealed only because it was in internal code. The public layer code was covered with checks. But you cannot reuse that internal code in the same assembly and cannot take it to your component. It won't work as expected because of the bug. So, I wrote [a unit test][corefx-test] of that internal code that revealed the bug. I treated the internal method as a unit to test. Keeping in mind that it's .NET Framework, I cannot easily refactor or change access modifiers of the existing code, I find that approach absolutely fine.

##### Complicated tests
I often see complicated tests, sometimes the logic of tests is even more complex than the code under test. And that always scares me. If I cannot easily understand them and add test cases for my needs, I try to avoid those tests and glad if they stay green. But if I need to spend hours just to figure out what's happening in that tests... I won't play that game: to make my colleagues or future me suffer. I'll just throw them away.

### Testing internals

So, coming back to the raised question:
> FAQ: How should you unit test internals?

A: It depends. If we're talking about unit tests then you're good to tests internals directly, even more, you're good to test privates if they have to be private and you need to test the logic. If we're talking about higher level tests such as Component then you shouldn't bother about internals.

To finish all that:
You absolutely OK not to write tests. I'm serious. There are other ways exist to mitigate consequences of bugs. If tests won't increase confidence for you or the team then don't do it. Don't waste your time, don't waste your colleagues' time. Tests for the sake of tests - they cost.



  [mark-seemann-post]: http://blog.ploeh.dk/2015/09/22/unit-testing-internals/
  [tdd-volkswagen]: https://en.wikipedia.org/wiki/Volkswagen_emissions_scandal
  [martin-fowler-test-pyramid]: http://martinfowler.com/bliki/TestPyramid.html
  [corefx-issue]: https://github.com/dotnet/corefx/issues/54
  [corefx-test]: https://github.com/dotnet/corefx/pull/1516
