---
layout: post
title: "Cross-Device Wheel: The Beginning"
date: 2015-11-12T16:54:23+02:00
modified:
categories: [Cross-Device]
excerpt: "The beginning of Cross-Device journey: a product that will change the chaotic online advertising market (I hope it won't add more chaos there:)"
tags: [Cross-Device]
comments: true
share: true
---

_Note: Originally posted in [the company's engineering blog][adform-post]._

### The wedding

For us, it all has started with a date… The date of our wedding.

![The wedding date]({{ site.url }}/images/cross-device-wheel-the-beginning/wedding-date.png)

A group of product managers and owners came to us, developers, with an idea of the Cross-Device solution and “some” requirements. The following business requirements were indicated:

* Connection of two IDs – deterministic and cookie ID;
* Return of a Unique ID.

There were also technical requirements specified:

* A strict “No” to the .NET framework;
* 1.000.000 Requests per Second (RPS);
* 5 millisecond response time;
* At least 500.000.000 Unique ID storage.

People, who came to us were .NET haters and us… Well, we laughed at 1 million RPS. But the date was set.

### We are architects

We started working on a proof of concept: we chose Scala as our programming language, Aerospike as a database, and Netty for the API. Straightforward mapping from cookies and deterministic IDs to Unique IDs was implemented in the first version and we delivered right on time. We even had some time to work on the design and architecture. As experienced guys in the team, we already knew that monoliths suck and microservices is the obvious way to go.
![monolith vs microservices]({{ site.url }}/images/cross-device-wheel-the-beginning/monolith-microservices.jpg)

The solution evolved over time. We have made internal integrations with Ad Serving, DMP and DSP platforms as well as several external integrations with Cross-Device data providers and pixel integrations with publishers. Targeting and attribution was covered later on; and here is how our architecture looks like at the moment:
![microservices]({{ site.url }}/images/cross-device-wheel-the-beginning/architecture.jpg)

### How Do We Work?

![90-fellas]({{ site.url }}/images/cross-device-wheel-the-beginning/90-fellas.gif)

We are not using Scrum, Kanban, or sprints; there is no planning, retro sessions and reviews; there are no estimates and velocity metrics.

Instead, we are [programming (obviously J)][programming-motherfucker] using the just-in-time model and, so far, everything happens when needed. We have invested in continuous deployment from the very beginning and now have up to few hundreds of releases a month. We also write tests, or at least we try, for building up the confidence. I believe, we are one awful team for managers because there is nothing to measure. However, there is the only true metric that exists out there – it is a working software which responds to the business needs.

### Not .NET = Scala at Adform

I, personally, love .NET and think that it is the best platform for rapid development of common needs. In specific areas, like High Load, however there are better solutions. You could be really good at .NET but, come on, it could still be compared to playing football on high heels.

![net-high-load]({{ site.url }}/images/cross-device-wheel-the-beginning/net-high-load.gif)

Now, back to Scala. The main point here is that it is the gateway to the Java and Linux world. I would say that Scala is “higher” than C# or Java. It has interesting concepts and patterns to learn and use.

What’s more, Aerospike is a great database. But it has this inferior async client which performance is 3 to 5 times worse than the synchronous’ one. However, the synchronous client is not too good as well; we have encountered some issues with the database itself.

Netty is excellent and the fastest for JVM. Not only was I pleased with the source code, but also Facebook has started using it and Google’s Open Bidder is based on Netty.

Akka-streams! I would call them the “Discovery of the Year” – they simply rock! It is a library for asynchronous stream processing which provides a way of expressing and running a chain of processing steps in a very efficient way. We are using Akka-streams in our backend services. The performance and how it utilizes all the resources is great; and it all happened without tuning. It even had to be throttled because it was producing a huge load.

### What’s Next?

There are some plans for the future already. We are preparing to introduce messaging system and be truly reactive. I hope, Kafka cluster will be ready for the wide usage soon! We also have to work on graph structures and databases to solve some issues but this is a separate topic.

  [adform-post]: http://engineering.adform.com/cross-device-wheel-the-beginning/
  [programming-motherfucker]: http://programming-motherfucker.com/
